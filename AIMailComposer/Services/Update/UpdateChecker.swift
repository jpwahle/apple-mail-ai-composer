import Foundation
import AppKit

@MainActor
final class UpdateChecker: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case idle
        case checking
        case downloading
        case readyToInstall
        case installing
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var latestVersion: String?
    @Published var releaseNotes: String?

    private let repo = "jpwahle/ai-apple-mail"
    private var downloadedDMG: URL?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    // MARK: - Version Comparison

    /// Returns true when `remote` is a strictly higher semver than `local`.
    static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        let len = max(r.count, l.count)
        for i in 0..<len {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }
}
