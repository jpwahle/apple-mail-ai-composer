import Foundation

/// Last-known model lists, persisted across launches. Loading this at startup
/// keeps the model picker populated even when the next fetch can't run yet —
/// e.g. the app launched at login before the network was up.
struct ModelCacheSnapshot: Codable {
    var models: [AIModel]
    var trending: [TrendingModel]
}

enum ModelCache {
    /// Serializes writes so overlapping saves from concurrent provider
    /// fetches can't land on disk out of order.
    private static let ioQueue = DispatchQueue(label: "com.aiMailComposer.modelCache", qos: .utility)

    private static var fileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AIMailComposer", isDirectory: true)
            .appendingPathComponent("model-cache.json")
    }

    static func load() -> ModelCacheSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(ModelCacheSnapshot.self, from: data)
    }

    static func save(_ snapshot: ModelCacheSnapshot) {
        let url = fileURL
        ioQueue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: url, options: .atomic)
        }
    }
}
