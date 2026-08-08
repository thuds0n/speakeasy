import AppKit

extension NSApplication {
    /// Opens the SwiftUI `Settings` scene. On macOS 13 there is no public API for this; SwiftUI
    /// responds to the private `showSettingsWindow:` selector. When the deployment target is
    /// raised to macOS 14+, replace the call sites with `SettingsLink` and delete this helper.
    func openSettingsWindow() {
        sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        activate(ignoringOtherApps: true)
    }
}
