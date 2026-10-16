import Foundation

/// Stores the raw JSON of the last successful lookup in the Caches directory.
struct AppsCache: Sendable, Equatable {
    let fileURL: URL

    init(developerID: Int, country: String) {
        let directory = URL.cachesDirectory.appending(path: "MyOtherApps", directoryHint: .isDirectory)
        self.fileURL = directory.appending(path: "\(developerID)-\(country).json")
    }

    func read() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}
