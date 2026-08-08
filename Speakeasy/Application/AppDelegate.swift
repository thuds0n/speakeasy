import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()
    let launchAtLoginController = LaunchAtLoginController(service: LaunchAtLoginService())

    private let hotKeyService: HotKeyServicing = HotKeyService()
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

        bindHotKey()
        openPreferencesIfNeeded()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        launchAtLoginController.refresh()
    }

    private func bindHotKey() {
        settings.$globalKey
            .sink { [hotKeyService] shortcut in
                hotKeyService.updateShortcut(shortcut)
            }
            .store(in: &cancellables)
    }

    private func openPreferencesIfNeeded() {
        guard settings.isShowPreference else { return }
        NSApp.openSettingsWindow()
    }
}
