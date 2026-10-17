import SwiftUI

/// A row with the icon, name, version and update date of an app, and a button that opens its App Store page.
///
/// The text wraps instead of truncating, and at accessibility text sizes the row stacks its content vertically. VoiceOver
/// reads the row as a single button that opens the App Store page.
struct StoreAppRow: View {
    let app: StoreApp

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var scaledIconSize = 44
    #if os(iOS)
    @State private var presentedAppID: Int?
    #else
    @Environment(\.openURL) private var openURL
    #endif

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var iconSize: CGFloat {
        min(scaledIconSize, 88)
    }

    var body: some View {
        let layout = isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            AsyncImage(url: app.artworkURL) { image in
                image.resizable()
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: iconSize, height: iconSize)
            // The corner radius of App Store icons is about 22% of their size.
            .clipShape(.rect(cornerRadius: iconSize * 0.22))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                Text(verbatim: "\(app.version) · \(app.currentVersionReleaseDate.formatted(.dateTime.day().month().year()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !isAccessibilitySize {
                Spacer(minLength: 0)
            }

            Button(action: presentAppStorePage) {
                Text("View", bundle: .module)
            }
                .font(.subheadline.bold())
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(app.name)
        .accessibilityValue(Text("Version \(app.version), updated \(app.currentVersionReleaseDate, format: .dateTime.day().month(.wide).year())", bundle: .module))
        .accessibilityHint(Text("Opens the App Store page", bundle: .module))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, presentAppStorePage)
        #if os(iOS)
        .background {
            StoreProductPresenter(appID: $presentedAppID)
        }
        #endif
    }

    /// Presents the App Store page inside the app on iOS. On macOS, where that isn't available, opens the App Store.
    private func presentAppStorePage() {
        #if os(iOS)
        presentedAppID = app.id
        #else
        openURL(app.storeURL)
        #endif
    }
}
