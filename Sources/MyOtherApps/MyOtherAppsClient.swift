import Foundation

/// Errors thrown by ``MyOtherAppsClient``.
public enum MyOtherAppsError: Error, Sendable {
    /// The iTunes API answered with a non-2xx HTTP status code.
    case badStatusCode(Int)
}

/// Fetches all the apps of a developer from the iTunes API and caches the response on disk.
///
/// Use the client directly when you want to render the apps with your own UI. The returned apps are
/// already filtered and sorted following ``hiddenAppIDs`` and ``order``:
///
/// 1. Apps whose identifier is in ``hiddenAppIDs`` are removed.
/// 2. Apps whose identifier is in ``order`` come first, in that order.
/// 3. The rest follow, sorted by ``StoreApp/currentVersionReleaseDate``, newest first.
///
/// Two clients are equal when they have the same configuration, so you can use a client as the
/// identifier of a `.task(id:)` to fetch again whenever the configuration changes.
///
/// ```swift
/// let client = MyOtherAppsClient(developerID: 1355340766)
/// for try await apps in client.apps() {
///     print(apps.map(\.name))
/// }
/// ```
public struct MyOtherAppsClient: Sendable, Equatable {
    /// The App Store identifier of the developer (the `id` in `apps.apple.com/developer/name/id123`).
    public let developerID: Int
    /// Identifiers of the apps that are never returned.
    public let hiddenAppIDs: Set<Int>
    /// Identifiers of the apps to show first, from most to least important.
    public let order: [Int]
    /// The two-letter code of the App Store storefront to fetch from, such as `"us"` or `"es"`.
    public let country: String

    private let session: URLSession
    private let cache: AppsCache

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - developerID: The App Store identifier of the developer.
    ///   - hiddenAppIDs: Identifiers of the apps that are never returned, such as the app the client runs in.
    ///   - order: Identifiers of the apps to show first, from most to least important. Apps not listed
    ///     here are sorted by the release date of their current version, newest first.
    ///   - country: The two-letter code of the App Store storefront to fetch from. Defaults to the
    ///     region of the current locale. App names are localized for this storefront.
    ///   - session: The URL session used for network requests.
    public init(
        developerID: Int,
        hiddenAppIDs: Set<Int> = [],
        order: [Int] = [],
        country: String = Locale.current.region?.identifier ?? "us",
        session: URLSession = .shared
    ) {
        self.developerID = developerID
        self.hiddenAppIDs = hiddenAppIDs
        self.order = order
        self.country = country.lowercased()
        self.session = session
        self.cache = AppsCache(developerID: developerID, country: self.country)
    }

    /// Returns the apps from the last successful fetch, or `nil` if nothing has been cached yet.
    public func cachedApps() -> [StoreApp]? {
        guard let data = cache.read(), let apps = try? LookupResponse.decode(from: data) else {
            return nil
        }
        return arranged(apps)
    }

    /// Fetches the apps from the iTunes API.
    ///
    /// On success, the response replaces the cached one, so it is returned by ``cachedApps()`` from then on.
    /// On failure, the cache is left untouched.
    public func fetchApps() async throws -> [StoreApp] {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: String(developerID)),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "country", value: country)
        ]

        let (data, response) = try await session.data(from: components.url!)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw MyOtherAppsError.badStatusCode(response.statusCode)
        }

        let apps = try LookupResponse.decode(from: data)
        try? cache.write(data)
        return arranged(apps)
    }

    /// Emits the cached apps first, if there are any, and then the apps fetched from the network.
    ///
    /// The stream finishes after the network result, or throws if the fetch fails. When the fetch fails,
    /// the cached apps have already been emitted, so you can keep showing them.
    public func apps() -> AsyncThrowingStream<[StoreApp], any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                if let cached = cachedApps() {
                    continuation.yield(cached)
                }
                do {
                    continuation.yield(try await fetchApps())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func arranged(_ apps: [StoreApp]) -> [StoreApp] {
        let visible = apps.filter { !hiddenAppIDs.contains($0.id) }
        let ordered = order.compactMap { id in visible.first { $0.id == id } }
        let rest = visible
            .filter { !order.contains($0.id) }
            .sorted { $0.currentVersionReleaseDate > $1.currentVersionReleaseDate }
        return ordered + rest
    }
}
