import AppKit

final class StatusBarItemManager {

    // MARK: - Constants

    private enum Lengths {
        static let visible: CGFloat = 20
        static let initial: CGFloat = 1
        static let collapsedMin: CGFloat = 500
        static let collapsedMax: CGFloat = 4000
        static let collapsedPad: CGFloat = 200
    }

    // MARK: - Status items

    let expandCollapse = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let separator      = NSStatusBar.system.statusItem(withLength: Lengths.initial)
    private(set) var alwaysHidden: NSStatusItem?

    // MARK: - State

    private let separatorImage = NSImage(named: NSImage.Name("ic_line"))
    private(set) var collapseLength: CGFloat = Lengths.collapsedMax

    var isCollapsed: Bool {
        separator.length == collapseLength
    }

    // MARK: - Init

    init() {
        refreshCollapseLength()
        separator.autosaveName = "speakeasy_separate"
        expandCollapse.autosaveName = "speakeasy_expandcollapse"
        separator.button?.image = separatorImage
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

    func hideSeparator() {
        guard isAlwaysHiddenInValidPosition else { return }
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
        item.autosaveName = "speakeasy_alwayshidden"
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
        let screenWidth = NSScreen.main?.visibleFrame.width ?? 1728
        collapseLength = max(Lengths.collapsedMin, min(screenWidth + Lengths.collapsedPad, Lengths.collapsedMax))
    }

    // MARK: - Position validation

    var isSeparatorInValidPosition: Bool {
        guard
            let toggleX   = expandCollapse.button?.windowOrigin?.x,
            let separateX = separator.button?.windowOrigin?.x
        else { return false }
        return Constant.isUsingLTRLanguage ? toggleX >= separateX : toggleX <= separateX
    }

    private var isAlwaysHiddenInValidPosition: Bool {
        guard Preferences.alwaysHiddenSectionEnabled else { return true }
        guard
            let separateX     = separator.button?.windowOrigin?.x,
            let alwaysHiddenX = alwaysHidden?.button?.windowOrigin?.x
        else { return false }
        return Constant.isUsingLTRLanguage ? separateX >= alwaysHiddenX : separateX <= alwaysHiddenX
    }
}
