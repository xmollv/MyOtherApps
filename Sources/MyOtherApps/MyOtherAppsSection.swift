import SwiftUI

/// A list section with one row per app of a developer, meant for a settings screen.
///
/// Each row shows the app icon, its name, its current version with the date it was released, and a
/// "View" button that presents the App Store page of the app without leaving your app. On macOS, the button opens
/// its App Store link instead.
///
/// The section shows the cached apps right away and refreshes them from the network when it appears.
/// Whenever any of its parameters changes, it shows the cached apps for the new parameters and fetches again.
///
/// The header reads "More apps by" followed by the developer name, translated into every language iOS
/// supports. Pass a title to use your own header instead.
///
/// ```swift
/// List {
///     MyOtherAppsSection(developerID: 1355340766)
/// }
/// ```
public struct MyOtherAppsSection: View {
    private let title: LocalizedStringKey?
    private let client: MyOtherAppsClient
    @State private var model: MyOtherAppsModel

    /// Creates a section that fetches the apps of a developer.
    ///
    /// - Parameters:
    ///   - title: The header of the section, looked up in your app's main bundle. Defaults to
    ///     "More apps by" followed by the developer name.
    ///   - developerID: The App Store identifier of the developer.
    ///   - hiddenAppIDs: Identifiers of the apps that are never shown. The app the section is in is never
    ///     shown either, without listing it here.
    ///   - order: Identifiers of the apps to show first, from most to least important. Apps not listed
    ///     here are sorted by the release date of their current version, newest first.
    ///   - country: The two-letter code of the App Store storefront to fetch from. Defaults to the
    ///     region of the current locale.
    public init(
        _ title: LocalizedStringKey? = nil,
        developerID: Int,
        hiddenAppIDs: Set<Int> = [],
        order: [Int] = [],
        country: String = Locale.current.region?.identifier ?? "us"
    ) {
        let client = MyOtherAppsClient(
            developerID: developerID,
            hiddenAppIDs: hiddenAppIDs,
            order: order,
            country: country
        )
        self.title = title
        self.client = client
        self._model = State(initialValue: MyOtherAppsModel(client: client))
    }

    public var body: some View {
        Section {
            if model.apps.isEmpty && model.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            ForEach(model.apps) { app in
                StoreAppRow(app: app)
            }
        } header: {
            // The header is rendered even when the section has no rows, so it's the one starting the load.
            header
                .task(id: client) {
                    if model.client != client {
                        model = MyOtherAppsModel(client: client)
                    }
                    await model.load()
                }
        }
    }

    private var header: Text {
        if let title {
            return Text(title)
        }
        if let developerName = model.apps.first?.developerName {
            return Text("More apps by \(developerName)", bundle: .module)
        }
        return Text("More apps", bundle: .module)
    }
}
