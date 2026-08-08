import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()

    private let hotKeyService: HotKeyServicing = HotKeyService()
    private let launchAtLoginService: LaunchAtLoginControlling = LaunchAtLoginService()
    private let applicationActivationService: ApplicationActivationControlling = ApplicationActivationService()
    private let autoCollapseTimer: AutoCollapseTiming = AutoCollapseTimer()
    private var statusBarCoordinator: StatusBarCoordinator?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarCoordinator = StatusBarCoordinator(
            settings: settings,
            applicationActivation: applicationActivationService,
            collapseTimer: autoCollapseTimer
        )
        hotKeyService.onKeyDown = { [weak self] in
            self?.statusBarCoordinator?.expandCollapseIfNeeded()
        }

        bindRuntimeServices()
        openPreferencesIfNeeded()
    }

    private func bindRuntimeServices() {
        settings.$globalKey
            .sink { [hotKeyService] shortcut in
                hotKeyService.updateShortcut(shortcut)
            }
            .store(in: &cancellables)

        settings.$isAutoStart
            .removeDuplicates()
            .sink { [launchAtLoginService] isEnabled in
                launchAtLoginService.setEnabled(isEnabled)
            }
            .store(in: &cancellables)
    }

    private func openPreferencesIfNeeded() {
        guard settings.isShowPreference else { return }
        NSApp.openSettingsWindow()
    }
}
