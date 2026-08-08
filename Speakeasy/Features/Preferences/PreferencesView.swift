import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var launchAtLogin: LaunchAtLoginController

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)
                .tabItem { Label("General", systemImage: "gearshape") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460)
    }
}
