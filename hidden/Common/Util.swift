import AppKit
import ServiceManagement

class Util {

    static func setUpAutoStart(isAutoStart: Bool) {
        do {
            if isAutoStart {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to \(isAutoStart ? "enable" : "disable") login item: \(error)")
        }
    }

    static func showPrefWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
