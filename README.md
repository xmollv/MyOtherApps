# MyOtherApps

A Swift package that fetches all the apps of an App Store developer from the iTunes API, and renders them as a SwiftUI section for your settings screen.

- Fetches every app of a developer with a single request to the public iTunes lookup API. No API key needed.
- The app it runs in is left out automatically. Hide more apps by identifier, and pin the most important ones to the top. The rest are sorted by their last update, newest first.
- Caches the last successful response on disk. The cached apps are always shown first, then replaced with the network result.
- A drop-in `Section` with one row per app: icon, name, version and last update date, and a **View** button that opens the App Store page without leaving your app.
- Translated into every language iOS supports, and adapts to Dynamic Type and VoiceOver.

Requires iOS 26 or later.

## Installation

Add the package to your project in Xcode with **File › Add Package Dependencies…**, or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/xmollv/MyOtherApps.git", branch: "main")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "MyOtherApps", package: "MyOtherApps")
    ])
]
```

## Finding your developer ID

Your developer ID is the number at the end of your developer page on the App Store, e.g. `https://apps.apple.com/us/developer/xavi-moll/id1355340766` → `1355340766`.

App IDs (for hiding and sorting) are found the same way in each app's App Store URL: `https://apps.apple.com/us/app/later-save-links-read-later/id1507396839` → `1507396839`.

## Rendering the provided UI

Drop `MyOtherAppsSection` inside a `List` or `Form`. It shows the cached apps right away and refreshes them from the network when it appears. If any of its parameters changes (for example, a user setting that hides apps), it shows the cached apps for the new parameters and fetches again.

```swift
import MyOtherApps
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            MyOtherAppsSection(
                developerID: 1355340766,
                // Don't show Llitgi. The app this runs in is never shown.
                hiddenAppIDs: [1355340767],
                // Show Later first. The rest follow, most recently updated first.
                order: [1507396839]
            )
        }
    }
}
```

The header reads "More apps by" followed by the developer name, for example "More apps by Xavi Moll". Until the first apps are loaded, it reads "More apps". To use your own header, pass it as the first argument. It's a `LocalizedStringKey` looked up in your app's main bundle, like any other `Text`:

```swift
MyOtherAppsSection("Our Other Apps", developerID: 1355340766)
```

### Accessibility

- Rows adapt to Dynamic Type. The text wraps instead of truncating, and at accessibility text sizes the row stacks the icon, text and **View** button vertically. The icon scales with the text, up to twice its regular size.
- VoiceOver reads each row as a single button: the app name, then its version and last update date. Activating it opens the App Store page.

### Localization

The default header, the **View** button and the VoiceOver strings ship translated into every language iOS supports: Arabic, Bangla, Catalan, Chinese (Simplified and Traditional), Croatian, Czech, Danish, Dutch, English, Finnish, French, German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Kazakh, Korean, Malay, Malayalam, Marathi, Norwegian, Odia, Polish, Portuguese (Brazil and Portugal), Punjabi, Romanian, Russian, Slovak, Slovenian, Spanish, Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu and Vietnamese. Dates are formatted for the user's locale.

iOS shows your whole app in one language, chosen among the languages **your app** supports. So the section is only translated into the languages your app is localized in. An app that only ships English shows the section in English, even on a device set to German.

App names come from the App Store storefront set by `country`, not from the device language.

## Fetching the data only

Use `MyOtherAppsClient` when you want to build your own UI. The apps it returns are already filtered and sorted.

### Cache first, then network

`apps()` returns an `AsyncThrowingStream` that emits the cached apps (if there are any) and then the fetched ones:

```swift
import MyOtherApps
import SwiftUI

struct MyAppsView: View {
    private let client = MyOtherAppsClient(
        developerID: 1355340766,
        hiddenAppIDs: [1355340767],
        order: [1507396839]
    )

    @State private var apps: [StoreApp] = []

    var body: some View {
        List(apps) { app in
            Link(app.name, destination: app.storeURL)
        }
        .task {
            do {
                for try await apps in client.apps() {
                    self.apps = apps
                }
            } catch {
                // The fetch failed. The cached apps, if any, have already been emitted.
            }
        }
    }
}
```

### Cache and network separately

```swift
let client = MyOtherAppsClient(developerID: 1355340766)

// Synchronous. `nil` if nothing has been fetched yet.
let cached = client.cachedApps()

// Fetches from the network and replaces the cache on success.
let fresh = try await client.fetchApps()
```

### Observable model

`MyOtherAppsModel` is the same `@Observable` model the section uses. It starts with the cached apps and exposes the loading state:

```swift
struct MyAppsView: View {
    @State private var model = MyOtherAppsModel(developerID: 1355340766)

    var body: some View {
        List(model.apps) { app in
            Text(app.name)
        }
        .overlay {
            if model.apps.isEmpty && model.isLoading {
                ProgressView()
            }
        }
        .refreshable { await model.load() }
        .task { await model.load() }
    }
}
```

## API reference

### `MyOtherAppsClient`

A `Sendable` and `Equatable` struct that fetches and caches the apps of a developer. Two clients are equal when they have the same configuration, so a client works as the identifier of a `.task(id:)` that fetches again when the configuration changes.

```swift
init(
    developerID: Int,
    hiddenAppIDs: Set<Int> = [],
    order: [Int] = [],
    country: String = Locale.current.region?.identifier ?? "us",
    session: URLSession = .shared
)
```

| Parameter | Description |
| --- | --- |
| `developerID` | The App Store identifier of the developer. |
| `hiddenAppIDs` | Identifiers of the apps that are never returned. The app the client runs in is never returned either: it's matched by `Bundle.main.bundleIdentifier`, so you don't need to list it. |
| `order` | Identifiers of the apps to return first, from most to least important. Apps not listed are sorted by `currentVersionReleaseDate`, newest first. |
| `country` | The two-letter code of the App Store storefront to fetch from. App names are localized for this storefront. Defaults to the region of the current locale. |
| `session` | The URL session used for network requests. |

| Method | Description |
| --- | --- |
| `func cachedApps() -> [StoreApp]?` | The apps from the last successful fetch, or `nil` if nothing has been cached yet. |
| `func fetchApps() async throws -> [StoreApp]` | Fetches the apps from the iTunes API. On success, the response replaces the cache. On failure, the cache is left untouched. |
| `func apps() -> AsyncThrowingStream<[StoreApp], any Error>` | Emits the cached apps first, if there are any, then the fetched apps. Throws if the fetch fails. |

The cache lives in the app's Caches directory, one file per developer ID and storefront.

### `MyOtherAppsModel`

A `@MainActor` `@Observable` class that wraps a `MyOtherAppsClient` for SwiftUI.

| Member | Description |
| --- | --- |
| `init(client: MyOtherAppsClient)` | Creates a model that uses the given client. |
| `init(developerID:hiddenAppIDs:order:country:)` | Creates a model with a client configured with the given parameters. |
| `let client: MyOtherAppsClient` | The client used to fetch the apps. |
| `private(set) var apps: [StoreApp]` | The apps to show. Starts with the cached apps. |
| `private(set) var isLoading: Bool` | Whether a fetch is in progress. |
| `private(set) var error: (any Error)?` | The error of the last fetch, or `nil` if it succeeded or is still in progress. |
| `func load() async` | Updates `apps` with the cached apps and then with the fetched apps. On failure, `apps` keeps its value and `error` is set. |

### `MyOtherAppsSection`

A SwiftUI `View` to use inside a `List` or `Form`.

| Initializer | Description |
| --- | --- |
| `init(_ title: LocalizedStringKey? = nil, developerID: Int, hiddenAppIDs: Set<Int> = [], order: [Int] = [], country: String = …)` | Creates a section that fetches the apps of a developer, and fetches again whenever a parameter changes. Without a `title`, the header reads "More apps by" followed by the developer name, translated into the user's language. |

### `StoreApp`

An app published on the App Store. `Identifiable`, `Hashable` and `Sendable`.

| Property | Description |
| --- | --- |
| `id: Int` | The App Store identifier of the app. |
| `name: String` | The name of the app, localized for the storefront it was fetched from. |
| `bundleID: String` | The bundle identifier of the app. |
| `developerName: String` | The name of the developer, as shown on the App Store. |
| `version: String` | The current version of the app. |
| `genre: String` | The localized name of the app's primary genre. |
| `artworkURL: URL` | The URL of the app's icon (512×512 when available). |
| `storeURL: URL` | The URL of the app's App Store page. |
| `releaseDate: Date` | The date the app was first released. |
| `currentVersionReleaseDate: Date` | The date the current version was released. |

`StoreApp` has a public memberwise initializer, handy for SwiftUI previews.

### `MyOtherAppsError`

| Case | Description |
| --- | --- |
| `badStatusCode(Int)` | The iTunes API answered with a non-2xx HTTP status code. |

Network and decoding errors are thrown as they are (`URLError`, `DecodingError`).

## Example app

`Example/MyOtherAppsExample.xcodeproj` is a settings screen with `MyOtherAppsSection`. It declares every language the package is translated into (`CFBundleLocalizations` in `Example/Info.plist`), so you can see the translations by changing the language of the app in the Settings app.

> The App Store page can't load in the iOS Simulator ("Cannot Connect to iTunes Store"). Use a real device to see it.
