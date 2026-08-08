import Combine
import Foundation
import OSLog
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

@MainActor
protocol LaunchAtLoginControlling: AnyObject {
    var status: LaunchAtLoginStatus { get }
    func setEnabled(_ isEnabled: Bool) throws
    func openSystemSettings()
}

@MainActor
final class LaunchAtLoginService: LaunchAtLoginControlling {
    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
    }

    var status: LaunchAtLoginStatus {
        switch service.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var status: LaunchAtLoginStatus
    @Published private(set) var errorMessage: String?

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy",
        category: "LaunchAtLogin"
    )

    private let service: LaunchAtLoginControlling

    init(service: LaunchAtLoginControlling) {
        self.service = service
        status = service.status
    }

    var isEnabled: Bool {
        status == .enabled
    }

    func setEnabled(_ isEnabled: Bool) {
        errorMessage = nil

        do {
            try service.setEnabled(isEnabled)
        } catch {
            errorMessage = error.localizedDescription
            Self.log.error(
                "Failed to \(isEnabled ? "enable" : "disable") login item: \(error.localizedDescription, privacy: .public)"
            )
        }

        status = service.status
    }

    func refresh() {
        errorMessage = nil
        status = service.status
    }

    func openSystemSettings() {
        service.openSystemSettings()
    }
}
