import MyOtherApps
import SwiftUI

/// A settings screen that drops in the section provided by the package.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                MyOtherAppsSection(
                    developerID: developerID,
                    // Llitgi for Pocket is hidden.
                    hiddenAppIDs: [1355340767],
                    // Later comes first, the rest are sorted by their last update.
                    order: [1507396839],
                    // Later is shown with a shorter name than on the App Store.
                    names: [1507396839: "Later"]
                )
            }
            .navigationTitle("Settings")
        }
    }
}
