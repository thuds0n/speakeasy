import AppKit

enum ApplicationActivationMode: Equatable {
    case menuBarExtraOnly
    case fullMenuBar
}

@MainActor
protocol ApplicationActivationControlling: AnyObject {
    func apply(_ mode: ApplicationActivationMode)
}

@MainActor
final class ApplicationActivationService: ApplicationActivationControlling {
    func apply(_ mode: ApplicationActivationMode) {
        switch mode {
        case .menuBarExtraOnly:
            let wasRegularApplication = NSApp.activationPolicy() == .regular
            NSApp.setActivationPolicy(.accessory)
            if wasRegularApplication {
                NSApp.deactivate()
            }

        case .fullMenuBar:
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
