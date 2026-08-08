import AppKit

extension GlobalKeybindPreferences {
    /// Build a shortcut from an `NSEvent`. Used by the shortcut recorder both for the final
    /// key-down capture (pass the typed characters) and for the live modifier-only preview
    /// shown during `flagsChanged` (pass `characters: nil`, `carbonFlags: 0`).
    static func from(event: NSEvent, characters: String?, carbonFlags: UInt32) -> GlobalKeybindPreferences {
        GlobalKeybindPreferences(
            function: event.modifierFlags.contains(.function),
            control:  event.modifierFlags.contains(.control),
            command:  event.modifierFlags.contains(.command),
            shift:    event.modifierFlags.contains(.shift),
            option:   event.modifierFlags.contains(.option),
            capsLock: event.modifierFlags.contains(.capsLock),
            carbonFlags: carbonFlags,
            characters: characters,
            keyCode: UInt32(event.keyCode)
        )
    }
}
