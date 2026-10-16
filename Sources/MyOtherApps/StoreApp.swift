import Foundation

/// An app published on the App Store by a developer.
public struct StoreApp: Identifiable, Hashable, Sendable {
    /// The App Store identifier of the app (the `trackId` in the iTunes API).
    public let id: Int
    /// The name of the app, localized for the storefront it was fetched from.
    public let name: String
    /// The bundle identifier of the app.
    public let bundleID: String
    /// The name of the developer of the app, as shown on the App Store.
    public let developerName: String
    /// The current version string of the app, as shown on the App Store.
    public let version: String
    /// The localized name of the app's primary genre, such as "Productivity".
    public let genre: String
    /// The URL of the app's icon, at the largest resolution provided by the API.
    public let artworkURL: URL
    /// The URL of the app's App Store page.
    public let storeURL: URL
    /// The date the app was first released on the App Store.
    public let releaseDate: Date
    /// The date the current version of the app was released.
    public let currentVersionReleaseDate: Date

    /// Creates an app. Useful for SwiftUI previews and for tests in your own app.
    public init(
        id: Int,
        name: String,
        bundleID: String,
        developerName: String,
        version: String,
        genre: String,
        artworkURL: URL,
        storeURL: URL,
        releaseDate: Date,
        currentVersionReleaseDate: Date
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.developerName = developerName
        self.version = version
        self.genre = genre
        self.artworkURL = artworkURL
        self.storeURL = storeURL
        self.releaseDate = releaseDate
        self.currentVersionReleaseDate = currentVersionReleaseDate
    }
}
