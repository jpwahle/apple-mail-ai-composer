import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    private let keychainService = KeychainService()

    init() {
        // Start from the last-known model lists so the picker (and the
        // stored model selection) works immediately, before — or without —
        // a successful fetch this launch.
        if let cached = ModelCache.load() {
            anthropicModels = cached.models.filter { $0.provider == .anthropic }
            openaiModels = cached.models.filter { $0.provider == .openai }
            geminiModels = cached.models.filter { $0.provider == .gemini }
            openrouterModels = cached.models.filter { $0.provider == .openrouter }
            trustedtokensModels = cached.models.filter { $0.provider == .trustedtokens }
            localModels = cached.models.filter { $0.provider == .local }
            trendingModels = cached.trending
            ensureDefaultSelection()
        }
    }

    @AppStorage("selectedModelID") var selectedModelID: String = ""
    // Disambiguates models that share an id across providers (e.g. the same
    // `vendor/model` slug exposed by both OpenRouter and TrustedTokens).
    // Empty for selections made before this field existed; `selectedModel`
    // falls back to id-only matching in that case.
    @AppStorage("selectedProviderRaw") var selectedProviderRaw: String = ""
    @AppStorage("customWritingInstructions") var customWritingInstructions: String = ""
    @AppStorage("hotkeyKeyCode") var hotkeyKeyCode: Int = 0x04    // kVK_ANSI_H
    @AppStorage("hotkeyModifiers") var hotkeyModifiers: Int = 0x0800 // optionKey

    static let hotkeyDidChange = Notification.Name("hotkeyDidChange")

    func setHotkey(keyCode: Int, modifiers: Int) {
        hotkeyKeyCode = keyCode
        hotkeyModifiers = modifiers
        NotificationCenter.default.post(name: Self.hotkeyDidChange, object: nil)
    }

    // MARK: - Launch at Login

    @Published var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update launch at login: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    @AppStorage("localAIBaseURL") var localAIBaseURL: String = ""

    @Published var anthropicModels: [AIModel] = []
    @Published var openaiModels: [AIModel] = []
    @Published var geminiModels: [AIModel] = []
    @Published var openrouterModels: [AIModel] = []
    @Published var trustedtokensModels: [AIModel] = []
    @Published var localModels: [AIModel] = []
    @Published var isFetchingAnthropic = false
    @Published var isFetchingOpenAI = false
    @Published var isFetchingGemini = false
    @Published var isFetchingOpenRouter = false
    @Published var isFetchingTrustedTokens = false
    @Published var isFetchingLocal = false
    @Published var anthropicFetchError: String?
    @Published var openaiFetchError: String?
    @Published var geminiFetchError: String?
    @Published var openrouterFetchError: String?
    @Published var trustedtokensFetchError: String?
    @Published var localFetchError: String?
    @Published var trendingModels: [TrendingModel] = []

    var allModels: [AIModel] {
        anthropicModels + openaiModels + geminiModels + openrouterModels + trustedtokensModels + localModels
    }

    /// Models grouped by provider. Within each group, sorted by release date
    /// descending (most recently released first), then by `tiebreakScore`.
    /// New flagship models land at the top without any hand-maintained list.
    var sortedGroupedModels: [(AIProvider, [AIModel])] {
        AIProvider.allCases.compactMap { provider in
            let models: [AIModel]
            switch provider {
            case .anthropic: models = anthropicModels
            case .openai: models = openaiModels
            case .gemini: models = geminiModels
            case .openrouter: models = openrouterModels
            case .trustedtokens: models = trustedtokensModels
            case .local: models = localModels
            }
            guard !models.isEmpty else { return nil }
            let sorted = models.sorted { lhs, rhs in
                let lk = lhs.sortKey
                let rk = rhs.sortKey
                if lk.0 != rk.0 { return lk.0 > rk.0 }
                return lk.1 > rk.1
            }
            return (provider, sorted)
        }
    }

    /// The most popular models across all providers. Uses trending data from
    /// OpenRouter's public API so the list stays current without hardcoded
    /// model names. Falls back to a recency-based heuristic when trending
    /// data isn't available.
    var popularModels: [AIModel] {
        if !trendingModels.isEmpty {
            var popular: [AIModel] = []
            for entry in trendingModels {
                var match: AIModel?

                // Try direct-API models for the entry's provider first
                if let provider = entry.provider {
                    let providerModels: [AIModel]
                    switch provider {
                    case .anthropic:     providerModels = anthropicModels
                    case .openai:        providerModels = openaiModels
                    case .gemini:        providerModels = geminiModels
                    case .openrouter:    providerModels = openrouterModels
                    case .trustedtokens: providerModels = trustedtokensModels
                    case .local:         providerModels = localModels
                    }
                    match = providerModels.first {
                        ModelFetcher.modelIDMatchesSlug($0.id, slug: entry.slug)
                    }
                }

                // Fall back to OpenRouter models by full ID
                if match == nil {
                    match = openrouterModels.first {
                        $0.id.lowercased() == entry.openRouterId.lowercased()
                    }
                }

                if let match, !popular.contains(match) {
                    popular.append(match)
                }
                if popular.count >= 5 { break }
            }
            if !popular.isEmpty { return popular }
        }

        // Fallback: top 3 newest from each provider, re-sorted. Keep one
        // model per id — SwiftUI lists key rows on the bare id, so two
        // providers' copies of the same id must not both appear.
        var candidates: [AIModel] = []
        for (_, provider) in sortedGroupedModels.enumerated() {
            candidates.append(contentsOf: provider.1.prefix(3))
        }
        var seenIDs = Set<String>()
        return candidates
            .sorted { lhs, rhs in
                let lk = lhs.sortKey
                let rk = rhs.sortKey
                if lk.0 != rk.0 { return lk.0 > rk.0 }
                return lk.1 > rk.1
            }
            .filter { seenIDs.insert($0.id).inserted }
            .prefix(5)
            .map { $0 }
    }

    var selectedModel: AIModel? {
        if let provider = AIProvider(rawValue: selectedProviderRaw) {
            // A pinned provider is resolved only within that provider — a
            // missing or still-loading model list must not reroute requests
            // to another provider's copy of the same id.
            return allModels.first { $0.id == selectedModelID && $0.provider == provider }
        }
        // Selections stored before `selectedProviderRaw` existed carry no
        // provider; match by id in `allModels` order, mirroring the original
        // resolution. The provider is stamped on the next explicit pick.
        return allModels.first { $0.id == selectedModelID }
    }

    /// True when `model` is the currently selected model. Provider-aware so
    /// two providers exposing the same id don't both show a checkmark.
    func isSelected(_ model: AIModel) -> Bool {
        guard model.id == selectedModelID else { return false }
        if let provider = AIProvider(rawValue: selectedProviderRaw) {
            return model.provider == provider
        }
        // Legacy id-only selection: mark the copy `selectedModel` resolves to.
        return selectedModel?.provider == model.provider
    }

    /// Record a user model selection, persisting both the id and the provider
    /// so the choice survives refetches even when another provider exposes the
    /// same id.
    func selectModel(_ model: AIModel) {
        selectedModelID = model.id
        selectedProviderRaw = model.provider.rawValue
    }

    /// Pick a sensible default model when none is set or the stored one
    /// disappeared from the latest fetch.
    func ensureDefaultSelection() {
        if let current = selectedModel, allModels.contains(current) {
            return
        }
        // A pinned selection whose provider hasn't delivered any models yet
        // (fetch pending or failed) may still resolve — don't replace it just
        // because another provider's fetch finished first.
        if !selectedModelID.isEmpty,
           let provider = AIProvider(rawValue: selectedProviderRaw),
           !allModels.contains(where: { $0.provider == provider }) {
            return
        }
        if let best = popularModels.first {
            selectModel(best)
        }
    }

    /// Drop a provider's models — e.g. after its API key or base URL was
    /// removed — from both the in-memory lists and the on-disk cache, so
    /// they don't resurface on the next launch.
    func clearModels(for provider: AIProvider) {
        switch provider {
        case .anthropic: anthropicModels = []; anthropicFetchError = nil
        case .openai: openaiModels = []; openaiFetchError = nil
        case .gemini: geminiModels = []; geminiFetchError = nil
        case .openrouter: openrouterModels = []; openrouterFetchError = nil
        case .trustedtokens: trustedtokensModels = []; trustedtokensFetchError = nil
        case .local: localModels = []; localFetchError = nil
        }
        persistModelCache()
    }

    private func persistModelCache() {
        ModelCache.save(ModelCacheSnapshot(models: allModels, trending: trendingModels))
    }

    func setAPIKey(_ key: String, for provider: AIProvider) throws {
        try keychainService.setKey(key, for: provider)
    }

    func getAPIKey(for provider: AIProvider) -> String? {
        keychainService.getKey(for: provider)
    }

    func deleteAPIKey(for provider: AIProvider) {
        keychainService.deleteKey(for: provider)
    }

    func makeAIClient() throws -> AIClient {
        guard let model = selectedModel else {
            throw AIClientError.requestFailed("No model selected. Open Settings and pick a model.")
        }
        return try AIClientFactory.client(for: model, keychainService: keychainService, localAIBaseURL: localAIBaseURL)
    }

    func fetchModels(for provider: AIProvider) async {
        switch provider {
        case .local:
            isFetchingLocal = true
            localFetchError = nil
            do {
                localModels = try await ModelFetcher.fetchLocalAIModels(
                    baseURL: localAIBaseURL,
                    apiKey: getAPIKey(for: .local)
                )
                ensureDefaultSelection()
            } catch {
                localFetchError = error.localizedDescription
            }
            isFetchingLocal = false

        default:
            guard let apiKey = getAPIKey(for: provider), !apiKey.isEmpty else { return }

            switch provider {
            case .anthropic:
                isFetchingAnthropic = true
                anthropicFetchError = nil
                do {
                    anthropicModels = try await ModelFetcher.fetchAnthropicModels(apiKey: apiKey)
                    ensureDefaultSelection()
                } catch {
                    anthropicFetchError = error.localizedDescription
                }
                isFetchingAnthropic = false

            case .openai:
                isFetchingOpenAI = true
                openaiFetchError = nil
                do {
                    openaiModels = try await ModelFetcher.fetchOpenAIModels(apiKey: apiKey)
                    ensureDefaultSelection()
                } catch {
                    openaiFetchError = error.localizedDescription
                }
                isFetchingOpenAI = false

            case .gemini:
                isFetchingGemini = true
                geminiFetchError = nil
                do {
                    geminiModels = try await ModelFetcher.fetchGeminiModels(apiKey: apiKey)
                    ensureDefaultSelection()
                } catch {
                    geminiFetchError = error.localizedDescription
                }
                isFetchingGemini = false

            case .openrouter:
                isFetchingOpenRouter = true
                openrouterFetchError = nil
                do {
                    openrouterModels = try await ModelFetcher.fetchOpenRouterModels(apiKey: apiKey)
                    ensureDefaultSelection()
                } catch {
                    openrouterFetchError = error.localizedDescription
                }
                isFetchingOpenRouter = false

            case .trustedtokens:
                isFetchingTrustedTokens = true
                trustedtokensFetchError = nil
                do {
                    trustedtokensModels = try await ModelFetcher.fetchTrustedTokensModels(apiKey: apiKey)
                    ensureDefaultSelection()
                } catch {
                    trustedtokensFetchError = error.localizedDescription
                }
                isFetchingTrustedTokens = false

            case .local:
                break // handled above
            }
        }

        // A failed fetch leaves the previous list untouched, so persisting
        // unconditionally never overwrites cached models with nothing.
        persistModelCache()
    }

    func fetchAllModels() async {
        // Fetch trending/popular rankings from OpenRouter (public, no auth)
        // in parallel with provider model lists.
        async let trending = ModelFetcher.fetchTrendingModels()

        await withTaskGroup(of: Void.self) { group in
            for provider in AIProvider.allCases {
                if provider == .local {
                    // The Local AI key is optional — attempt if a URL is set.
                    if !localAIBaseURL.isEmpty {
                        group.addTask { await self.fetchModels(for: .local) }
                    }
                } else if let key = getAPIKey(for: provider), !key.isEmpty {
                    group.addTask { await self.fetchModels(for: provider) }
                }
            }
        }

        // fetchTrendingModels returns [] on any failure — keep the cached
        // ranking in that case so `popularModels` doesn't degrade offline.
        let fetchedTrending = await trending
        if !fetchedTrending.isEmpty {
            trendingModels = fetchedTrending
            persistModelCache()
        }
    }

    // MARK: - Auto Refresh

    /// How often to silently re-fetch model lists while the app runs, so
    /// newly released models appear without re-saving an API key.
    private static let modelRefreshInterval: TimeInterval = 6 * 60 * 60
    /// Retry ladder used while a configured provider's fetch is failing —
    /// most commonly a launch at login before the network is up.
    private static let retryDelays: [TimeInterval] = [30, 60, 120, 300, 900, 1800]

    private var autoRefreshTask: Task<Void, Never>?

    /// Fetch models now, then keep them fresh for the app's lifetime:
    /// refetch on a regular interval, or with backoff while fetches fail.
    func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }
        autoRefreshTask = Task { [weak self] in
            var failedAttempts = 0
            while !Task.isCancelled {
                let delay: TimeInterval
                // Scope the strong reference so it isn't held across the
                // (potentially hours-long) sleep below.
                do {
                    guard let self else { return }
                    await self.fetchAllModels()
                    if self.hasFetchFailures {
                        delay = Self.retryDelays[min(failedAttempts, Self.retryDelays.count - 1)]
                        failedAttempts += 1
                    } else {
                        failedAttempts = 0
                        delay = Self.modelRefreshInterval
                    }
                }
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    /// True when at least one configured provider's last fetch failed.
    private var hasFetchFailures: Bool {
        if !localAIBaseURL.isEmpty, localFetchError != nil { return true }
        for provider in AIProvider.allCases where provider != .local {
            guard let key = getAPIKey(for: provider), !key.isEmpty else { continue }
            let error: String?
            switch provider {
            case .anthropic: error = anthropicFetchError
            case .openai: error = openaiFetchError
            case .gemini: error = geminiFetchError
            case .openrouter: error = openrouterFetchError
            case .trustedtokens: error = trustedtokensFetchError
            case .local: error = nil
            }
            if error != nil { return true }
        }
        return false
    }
}
