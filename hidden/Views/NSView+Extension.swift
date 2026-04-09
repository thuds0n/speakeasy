import AppKit

extension NSView {
    var windowOrigin: CGPoint? {
        return self.window?.frame.origin
    }
}
