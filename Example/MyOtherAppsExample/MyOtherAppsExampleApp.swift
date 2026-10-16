import SwiftUI

let developerID = 1355340766

@main
struct MyOtherAppsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                }
            }
        }
    }
}
