import SwiftUI
import HotKey
import Carbon

/// A button that captures the next key press as a global shortcut.
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: GlobalKeybindPreferences?

    func makeCoordinator() -> Coordinator { Coordinator(shortcut: $shortcut) }

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let view = ShortcutRecorderButton()
        let coordinator = context.coordinator
        view.onCapture = { captured in
            coordinator.apply(captured)
        }
        view.onClear = {
            coordinator.clear()
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.currentShortcut = shortcut
    }

    // MARK: - Coordinator

    final class Coordinator {
        private var shortcut: Binding<GlobalKeybindPreferences?>

        init(shortcut: Binding<GlobalKeybindPreferences?>) {
            self.shortcut = shortcut
        }

        func apply(_ captured: GlobalKeybindPreferences) {
            shortcut.wrappedValue = captured
            Preferences.globalKey = captured
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            appDelegate.hotKey = HotKey(keyCombo: KeyCombo(
                carbonKeyCode: captured.keyCode,
                carbonModifiers: captured.carbonFlags
            ))
        }

        func clear() {
            shortcut.wrappedValue = nil
            Preferences.globalKey = nil
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            appDelegate.hotKey = nil
        }
    }
}

// MARK: - ShortcutRecorderButton

final class ShortcutRecorderButton: NSView {
    var currentShortcut: GlobalKeybindPreferences? { didSet { refresh() } }
    var onCapture: ((GlobalKeybindPreferences) -> Void)?
    var onClear: (() -> Void)?

    private let setButton = NSButton(title: "", target: nil, action: nil)
    private let clearButton = NSButton(title: "Clear", target: nil, action: nil)

    private var isListening = false {
        didSet {
            setButton.highlight(isListening)
            refresh()
            if isListening { window?.makeFirstResponder(self) }
        }
    }

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setButton.bezelStyle = .rounded
        setButton.target = self
        setButton.action = #selector(startListening)

        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearShortcut)
        clearButton.isEnabled = false

        let stack = NSStackView(views: [setButton, clearButton])
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        refresh()
    }

    // MARK: - State

    private func refresh() {
        if isListening {
            setButton.title = "Type shortcut…"
            setButton.setAccessibilityLabel("Listening for keyboard shortcut")
        } else if let s = currentShortcut {
            setButton.title = s.description.isEmpty ? "Set Shortcut" : s.description
            setButton.setAccessibilityLabel("Current shortcut: \(s.description). Click to change.")
        } else {
            setButton.title = "Set Shortcut"
            setButton.setAccessibilityLabel("Click to set a global keyboard shortcut")
        }
        clearButton.isEnabled = currentShortcut != nil && !isListening
    }

    // MARK: - Actions

    @objc private func startListening() {
        isListening = true
    }

    @objc private func clearShortcut() {
        currentShortcut = nil
        isListening = false
        onClear?()
    }

    // MARK: - Key capture

    override var acceptsFirstResponder: Bool { isListening }

    override func keyDown(with event: NSEvent) {
        guard isListening else { super.keyDown(with: event); return }
        // Escape cancels without changing the shortcut
        if event.keyCode == UInt16(kVK_Escape) { isListening = false; return }
        guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return }

        let captured = GlobalKeybindPreferences(
            function: event.modifierFlags.contains(.function),
            control:  event.modifierFlags.contains(.control),
            command:  event.modifierFlags.contains(.command),
            shift:    event.modifierFlags.contains(.shift),
            option:   event.modifierFlags.contains(.option),
            capsLock: event.modifierFlags.contains(.capsLock),
            carbonFlags: event.modifierFlags.carbonFlags,
            characters: chars,
            keyCode: UInt32(event.keyCode)
        )

        currentShortcut = captured
        isListening = false
        onCapture?(captured)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isListening else { return }
        // Show modifier preview while waiting for the key character
        if !event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
            let preview = GlobalKeybindPreferences(
                function: event.modifierFlags.contains(.function),
                control:  event.modifierFlags.contains(.control),
                command:  event.modifierFlags.contains(.command),
                shift:    event.modifierFlags.contains(.shift),
                option:   event.modifierFlags.contains(.option),
                capsLock: event.modifierFlags.contains(.capsLock),
                carbonFlags: 0,
                characters: nil,
                keyCode: UInt32(event.keyCode)
            )
            setButton.title = preview.description.isEmpty ? "Type shortcut…" : "\(preview.description)…"
        } else {
            setButton.title = "Type shortcut…"
        }
    }

    override func resignFirstResponder() -> Bool {
        isListening = false
        return super.resignFirstResponder()
    }
}
