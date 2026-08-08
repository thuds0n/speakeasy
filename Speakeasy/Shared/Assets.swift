import AppKit

struct Assets {
    private static var isLeftToRight: Bool {
        NSApplication.shared.userInterfaceLayoutDirection == .leftToRight
    }

    static var expandImage: NSImage? {
        NSImage(named: NSImage.Name(isLeftToRight ? "ic_expand" : "ic_collapse"))
    }

    static var collapseImage: NSImage? {
        NSImage(named: NSImage.Name(isLeftToRight ? "ic_collapse" : "ic_expand"))
    }
}
