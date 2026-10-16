import Foundation
import Observation

/// An observable wrapper around ``MyOtherAppsClient`` for SwiftUI.
///
/// The model starts with the cached apps, so the first frame already shows them. Call ``load()``
/// to refresh them from the network. ``MyOtherAppsSection`` uses this model, and you can use it too
/// when building your own UI.
///
/// ```swift
/// @State private var model = MyOtherAppsModel(developerID: 1355340766)
///
/// var body: some View {
///     List(model.apps) { app in
///         Text(app.name)
///     }
///     .task { await model.load() }
/// }
/// ```
@MainActor
@Observable
public final class MyOtherAppsModel {
    /// The client used to fetch the apps.
    public let client: MyOtherAppsClient
    /// The apps to show, filtered and sorted as configured in ``client``.
    public private(set) var apps: [StoreApp]
    /// Whether a fetch is in progress.
    public private(set) var isLoading = false
    /// The error of the last fetch, or `nil` if it succeeded or is still in progress.
    public private(set) var error: (any Error)?

    /// Creates a model that uses the given client.
    public init(client: MyOtherAppsClient) {
        self.client = client
        self.apps = client.cachedApps() ?? []
    }

    /// Creates a model with a client configured with the given parameters.
    ///
    /// See ``MyOtherAppsClient/init(developerID:hiddenAppIDs:order:country:session:)`` for the
    /// meaning of each parameter.
    public convenience init(
        developerID: Int,
        hiddenAppIDs: Set<Int> = [],
        order: [Int] = [],
        country: String = Locale.current.region?.identifier ?? "us"
    ) {
        self.init(client: MyOtherAppsClient(
            developerID: developerID,
            hiddenAppIDs: hiddenAppIDs,
            order: order,
            country: country
        ))
    }

    /// Updates ``apps`` with the cached apps and then with the apps fetched from the network.
    ///
    /// If the fetch fails, ``apps`` keeps its current value and ``error`` is set.
    public func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            for try await apps in client.apps() {
                self.apps = apps
            }
        } catch {
            self.error = error
        }
    }
}
