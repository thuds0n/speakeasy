import Foundation
import OSLog
import ServiceManagement

protocol LaunchAtLoginControlling {
    func setEnabled(_ isEnabled: Bool)
}

final class LaunchAtLoginService: LaunchAtLoginControlling {
    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy",
        category: "LaunchAtLogin"
    )

    func setEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.log.error("Failed to \(isEnabled ? "enable" : "disable") login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
