import AppKit

class StatusBarController {

    // MARK: - Dependencies

    private let items = StatusBarItemManager()
    private let collapseTimer = AutoCollapseTimer()

    // Debounce flag to prevent rapid expand/collapse creating Dock icons
    private var isToggling = false

    // MARK: - Init / deinit

    init() {
        setupExpandCollapseButton()
        setupContextMenu()
        setupAlwaysHiddenSection()

        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenParametersChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePrefsChanged), name: .prefsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAlwaysHideToggle), name: .alwaysHideToggle, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.items.collapse()
            self?.updateToggleButtonImage()
        }

        if Preferences.areSeparatorsHidden { items.hideSeparator() }
        scheduleAutoCollapseIfNeeded()
    }

    deinit {
        collapseTimer.stop()
        NotificationCenter.default.removeObserver(self)
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

        updateAutoCollapseMenuTitle()
    }

    private func setupAlwaysHiddenSection() {
        if Preferences.alwaysHiddenSectionEnabled {
            items.enableAlwaysHidden()
        }
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
        guard !isToggling else { return }
        isToggling = true
        items.isCollapsed ? expand() : collapse()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isToggling = false
        }
    }

    private func collapse() {
        items.collapse()
        updateToggleButtonImage()
        if Preferences.useFullStatusBarOnExpandEnabled {
            NSApp.setActivationPolicy(.accessory)
            NSApp.deactivate()
        }
    }

    private func expand() {
        items.expand()
        updateToggleButtonImage()
        scheduleAutoCollapseIfNeeded()
        if Preferences.useFullStatusBarOnExpandEnabled {
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
        if Preferences.areSeparatorsHidden {
            items.showSeparator()
            Preferences.areSeparatorsHidden = false
        } else {
            items.hideSeparator()
            Preferences.areSeparatorsHidden = true
        }
        if items.isCollapsed { expand() }
    }

    // MARK: - Auto-collapse

    private func scheduleAutoCollapseIfNeeded() {
        guard Preferences.isAutoHide, !items.isCollapsed else { return }
        collapseTimer.start(interval: Preferences.numberOfSecondForAutoHide) { [weak self] in
            guard Preferences.isAutoHide else { return }
            self?.collapse()
            self?.updateToggleButtonImage()
        }
    }

    // MARK: - Context menu helpers

    private func updateAutoCollapseMenuTitle() {
        guard let item = items.separator.menu?.item(withTag: 1) else { return }
        item.title = Preferences.isAutoHide
            ? "Disable Auto Collapse".localized
            : "Enable Auto Collapse".localized
    }

    @objc private func toggleAutoHide() {
        Preferences.isAutoHide.toggle()
    }

    @objc private func openPreferences() {
        Util.showPrefWindow()
    }

    // MARK: - Notification handlers

    @objc private func handleScreenParametersChanged() {
        items.refreshCollapseLength()
    }

    @objc private func handlePrefsChanged() {
        updateAutoCollapseMenuTitle()
        scheduleAutoCollapseIfNeeded()
    }

    @objc private func handleAlwaysHideToggle() {
        items.refreshCollapseLength()
        if Preferences.alwaysHiddenSectionEnabled {
            items.enableAlwaysHidden()
        } else {
            items.disableAlwaysHidden()
        }
    }
}
