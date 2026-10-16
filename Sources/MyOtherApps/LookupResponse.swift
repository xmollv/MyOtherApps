import Foundation

/// The body returned by the iTunes lookup endpoint.
///
/// The first result is the developer itself (`wrapperType == "artist"`), followed by one result per app.
struct LookupResponse: Decodable {
    struct Result: Decodable {
        let wrapperType: String
        let trackId: Int?
        let trackName: String?
        let bundleId: String?
        let artistName: String?
        let version: String?
        let primaryGenreName: String?
        let artworkUrl512: URL?
        let artworkUrl100: URL?
        let trackViewUrl: URL?
        let releaseDate: Date?
        let currentVersionReleaseDate: Date?
    }

    let results: [Result]

    static func decode(from data: Data) throws -> [StoreApp] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(LookupResponse.self, from: data)
        return response.results.compactMap(StoreApp.init)
    }
}

private extension StoreApp {
    init?(_ result: LookupResponse.Result) {
        guard
            result.wrapperType == "software",
            let id = result.trackId,
            let name = result.trackName,
            let bundleID = result.bundleId,
            let developerName = result.artistName,
            let version = result.version,
            let artworkURL = result.artworkUrl512 ?? result.artworkUrl100,
            let storeURL = result.trackViewUrl,
            let releaseDate = result.releaseDate,
            let currentVersionReleaseDate = result.currentVersionReleaseDate
        else {
            return nil
        }

        self.init(
            id: id,
            name: name,
            bundleID: bundleID,
            developerName: developerName,
            version: version,
            genre: result.primaryGenreName ?? "",
            artworkURL: artworkURL,
            storeURL: storeURL,
            releaseDate: releaseDate,
            currentVersionReleaseDate: currentVersionReleaseDate
        )
    }
}
