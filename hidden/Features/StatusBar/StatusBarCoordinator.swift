import AppKit
import Combine

@MainActor
final class StatusBarCoordinator {

    // MARK: - Dependencies

    private let settings: SettingsStore
    private let items = StatusBarItemManager()
    private let collapseTimer = AutoCollapseTimer()
    private var cancellables = Set<AnyCancellable>()

    // Debounce state for expand/collapse. A pending `Task` acts as the cooldown window;
    // while it's alive, further toggles are ignored.
    private var toggleCooldown: Task<Void, Never>?

    // MARK: - Init / deinit

    init(settings: SettingsStore) {
        self.settings = settings

        setupExpandCollapseButton()
        setupContextMenu()
        applyAlwaysHiddenSection(isEnabled: settings.alwaysHiddenSectionEnabled)
        applySeparatorVisibility(hidden: settings.areSeparatorsHidden, expandIfCollapsed: false)
        updateAutoCollapseMenuTitle()
        bindSettings()
        observeScreenChanges()

        // Delay the initial collapse so the system has time to lay out our status items.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self else { return }
            self.items.collapse()
            self.updateToggleButtonImage()
            self.updateAutoCollapseScheduling()
        }
    }

    deinit {
        toggleCooldown?.cancel()
        collapseTimer.stop()
    }

    // MARK: - Setup

    private func setupExpandCollapseButton() {
        guard let button = items.expandCollapse.button else { return }
        button.image = Assets.collapseImage
        button.target = self
        button.action = #selector(expandCollapseButtonPressed)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.setAccessibilityLabel("Expand hidden menu bar items")
    }

    private func setupContextMenu() {
        let menu = NSMenu()

        let prefItem = NSMenuItem(title: "Preferences...".localized, action: #selector(openPreferences), keyEquivalent: "P")
        prefItem.target = self
        menu.addItem(prefItem)

        let toggleItem = NSMenuItem(title: "", action: #selector(toggleAutoHide), keyEquivalent: "t")
        toggleItem.target = self
        toggleItem.tag = 1
        menu.addItem(toggleItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit".localized, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        items.separator.menu = menu
        items.separator.button?.image = NSImage(named: NSImage.Name("ic_line"))
        items.separator.button?.setAccessibilityLabel("Hidden section separator. Right-click for options.")

    }

    // MARK: - Button action

    @objc private func expandCollapseButtonPressed(sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        let isOption = event.modifierFlags.contains(.option)
        if event.type == .leftMouseUp && !isOption {
            expandCollapseIfNeeded()
        } else {
            toggleSeparatorVisibility()
        }
    }

    // MARK: - Expand / collapse

    func expandCollapseIfNeeded() {
        guard toggleCooldown == nil else { return }
        items.isCollapsed ? expand() : collapse()
        toggleCooldown = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            self?.toggleCooldown = nil
        }
    }

    private func collapse() {
        items.collapse()
        updateToggleButtonImage()
        updateAutoCollapseScheduling()

        if settings.useFullStatusBarOnExpandEnabled {
            NSApp.setActivationPolicy(.accessory)
            NSApp.deactivate()
        }
    }

    private func expand() {
        items.expand()
        updateToggleButtonImage()
        updateAutoCollapseScheduling()

        if settings.useFullStatusBarOnExpandEnabled {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateToggleButtonImage() {
        items.expandCollapse.button?.image = items.isCollapsed ? Assets.expandImage : Assets.collapseImage
        items.expandCollapse.button?.setAccessibilityLabel(items.isCollapsed
            ? "Expand hidden menu bar items"
            : "Collapse menu bar items")
    }

    // MARK: - Separator visibility

    private func toggleSeparatorVisibility() {
        settings.areSeparatorsHidden.toggle()
    }

    private func applySeparatorVisibility(hidden: Bool, expandIfCollapsed: Bool) {
        if hidden {
            items.hideSeparator(alwaysHiddenEnabled: settings.alwaysHiddenSectionEnabled)
        } else {
            items.showSeparator()
        }

        if expandIfCollapsed && items.isCollapsed {
            expand()
        }
    }

    // MARK: - Auto-collapse

    private func updateAutoCollapseScheduling() {
        collapseTimer.stop()

        guard settings.isAutoHide, !items.isCollapsed else { return }

        collapseTimer.start(interval: settings.autoHideDuration) { [weak self] in
            guard let self, self.settings.isAutoHide else { return }
            self.collapse()
            self.updateToggleButtonImage()
        }
    }

    // MARK: - Context menu helpers

    private func updateAutoCollapseMenuTitle() {
        guard let item = items.separator.menu?.item(withTag: 1) else { return }
        item.title = settings.isAutoHide
            ? "Disable Auto Collapse".localized
            : "Enable Auto Collapse".localized
    }

    @objc private func toggleAutoHide() {
        settings.isAutoHide.toggle()
    }

    @objc private func openPreferences() {
        NSApp.openSettingsWindow()
    }

    // MARK: - Settings binding

    private func bindSettings() {
        settings.$isAutoHide
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateAutoCollapseMenuTitle()
                self?.updateAutoCollapseScheduling()
            }
            .store(in: &cancellables)

        settings.$autoHideDuration
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateAutoCollapseScheduling()
            }
            .store(in: &cancellables)

        settings.$alwaysHiddenSectionEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.applyAlwaysHiddenSection(isEnabled: isEnabled)
            }
            .store(in: &cancellables)

        settings.$areSeparatorsHidden
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isHidden in
                self?.applySeparatorVisibility(hidden: isHidden, expandIfCollapsed: true)
            }
            .store(in: &cancellables)
    }

    private func observeScreenChanges() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.items.refreshCollapseLength()
            }
            .store(in: &cancellables)
    }

    private func applyAlwaysHiddenSection(isEnabled: Bool) {
        items.refreshCollapseLength()

        if isEnabled {
            items.enableAlwaysHidden()
        } else {
            items.disableAlwaysHidden()
        }

        applySeparatorVisibility(hidden: settings.areSeparatorsHidden, expandIfCollapsed: false)
    }
}
