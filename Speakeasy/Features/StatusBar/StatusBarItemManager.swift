import AppKit

@MainActor
final class StatusBarItemManager {

    // MARK: - Constants

    /// All values are in points — the unit `NSStatusItem.length` uses.
    /// "Collapsed" means the separator item is stretched wide enough to push the icons left of
    /// it off-screen; its length is sized to cover the entire menu bar width on the current
    /// screen (`collapsedMin…collapsedMax`, plus a `collapsedPad` safety margin).
    private enum Lengths {
        static let visible: CGFloat = 20
        static let initial: CGFloat = 1
        static let collapsedMin: CGFloat = 500
        /// Hard ceiling so `separator.length` never grows unbounded across display changes
        /// (observed memory growth previously; see commit a971149).
        static let collapsedMax: CGFloat = 4000
        /// Safety margin added to screen width so the separator fully covers icons even when
        /// the reported width underestimates the visible frame (e.g. notch-aware displays).
        static let collapsedPad: CGFloat = 200
    }

    // MARK: - Status items

    let expandCollapse = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let separator      = NSStatusBar.system.statusItem(withLength: Lengths.initial)
    private(set) var alwaysHidden: NSStatusItem?

    // MARK: - State

    private let separatorImage = NSImage(named: NSImage.Name("ic_line"))
    private let autosaveNamePrefix: String
    private(set) var collapseLength: CGFloat = Lengths.collapsedMax

    var isCollapsed: Bool {
        separator.length > Lengths.visible
    }

    // MARK: - Init

    init(autosaveNamePrefix: String = "speakeasy") {
        self.autosaveNamePrefix = autosaveNamePrefix
        refreshCollapseLength()
        separator.autosaveName = "\(autosaveNamePrefix)_separate"
        expandCollapse.autosaveName = "\(autosaveNamePrefix)_expandcollapse"
        separator.button?.image = separatorImage
    }

    deinit {
        NSStatusBar.system.removeStatusItem(expandCollapse)
        NSStatusBar.system.removeStatusItem(separator)
        if let alwaysHidden {
            NSStatusBar.system.removeStatusItem(alwaysHidden)
        }
    }

    // MARK: - Collapse / expand

    func collapse() {
        guard isSeparatorInValidPosition, !isCollapsed else { return }
        separator.length = collapseLength
    }

    func expand() {
        guard isCollapsed else { return }
        separator.length = Lengths.visible
    }

    // MARK: - Separator visibility

    func showSeparator() {
        if !isCollapsed { separator.length = Lengths.visible }
        alwaysHidden?.length = Lengths.visible
    }

    func hideSeparator(alwaysHiddenEnabled: Bool) {
        guard isAlwaysHiddenInValidPosition(alwaysHiddenEnabled: alwaysHiddenEnabled) else { return }
        if !isCollapsed { separator.length = Lengths.visible }
        alwaysHidden?.length = collapseLength
    }

    // MARK: - Always-hidden section

    func enableAlwaysHidden() {
        if let existing = alwaysHidden {
            NSStatusBar.system.removeStatusItem(existing)
        }
        refreshCollapseLength()
        let item = NSStatusBar.system.statusItem(withLength: Lengths.visible)
        item.autosaveName = "\(autosaveNamePrefix)_alwayshidden"
        item.button?.image = separatorImage
        item.button?.appearsDisabled = true
        alwaysHidden = item
    }

    func disableAlwaysHidden() {
        if let existing = alwaysHidden {
            NSStatusBar.system.removeStatusItem(existing)
        }
        alwaysHidden = nil
        refreshCollapseLength()
    }

    // MARK: - Screen adaptation

    func refreshCollapseLength() {
        let wasCollapsed = isCollapsed
        let wasAlwaysHiddenHidden = (alwaysHidden?.length ?? 0) > Lengths.visible
        let screenWidth = NSScreen.main?.visibleFrame.width ?? 1728
        collapseLength = max(Lengths.collapsedMin, min(screenWidth + Lengths.collapsedPad, Lengths.collapsedMax))

        if wasCollapsed {
            separator.length = collapseLength
        }

        if wasAlwaysHiddenHidden {
            alwaysHidden?.length = collapseLength
        }
    }

    // MARK: - Position validation

    var isSeparatorInValidPosition: Bool {
        guard
            let toggleX = expandCollapse.button?.window?.frame.origin.x,
            let separateX = separator.button?.window?.frame.origin.x
        else { return false }
        return isLeftToRight ? toggleX >= separateX : toggleX <= separateX
    }

    private func isAlwaysHiddenInValidPosition(alwaysHiddenEnabled: Bool) -> Bool {
        guard alwaysHiddenEnabled else { return true }
        guard
            let separateX = separator.button?.window?.frame.origin.x,
            let alwaysHiddenX = alwaysHidden?.button?.window?.frame.origin.x
        else { return false }
        return isLeftToRight ? separateX >= alwaysHiddenX : separateX <= alwaysHiddenX
    }

    private var isLeftToRight: Bool {
        NSApplication.shared.userInterfaceLayoutDirection == .leftToRight
    }
}
