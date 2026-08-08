import SwiftUI

@main
struct SpeakeasyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView(settings: appDelegate.settings)
        }
    }
}
