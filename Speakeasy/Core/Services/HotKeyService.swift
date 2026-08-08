import HotKey

@MainActor
protocol HotKeyServicing: AnyObject {
    var onKeyDown: (() -> Void)? { get set }
    func updateShortcut(_ shortcut: GlobalKeybindPreferences?)
}

@MainActor
final class HotKeyService: HotKeyServicing {
    var onKeyDown: (() -> Void)? {
        didSet {
            updateHandler()
        }
    }

    private var hotKey: HotKey? {
        didSet {
            updateHandler()
        }
    }

    func updateShortcut(_ shortcut: GlobalKeybindPreferences?) {
        guard let shortcut else {
            hotKey = nil
            return
        }

        hotKey = HotKey(
            keyCombo: KeyCombo(
                carbonKeyCode: shortcut.keyCode,
                carbonModifiers: shortcut.carbonFlags
            )
        )
    }

    private func updateHandler() {
        hotKey?.keyDownHandler = { [weak self] in
            self?.onKeyDown?()
        }
    }
}
