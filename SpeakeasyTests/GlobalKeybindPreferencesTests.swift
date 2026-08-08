import XCTest
@testable import Speakeasy

final class GlobalKeybindPreferencesTests: XCTestCase {

    func testDescriptionRendersReturnKey() {
        let shortcut = make(keyCode: 36, characters: nil)
        XCTAssertEqual(shortcut.description, "⏎")
    }

    func testDescriptionRendersDeleteKey() {
        let shortcut = make(keyCode: 51, characters: nil)
        XCTAssertEqual(shortcut.description, "⌫")
    }

    func testDescriptionRendersSpaceKey() {
        let shortcut = make(keyCode: 49, characters: nil)
        XCTAssertEqual(shortcut.description, "⎵")
    }

    func testDescriptionRendersModifiersAndCharacter() {
        let shortcut = make(command: true, shift: true, keyCode: 4, characters: "h")
        XCTAssertEqual(shortcut.description, "⌘⇧H")
    }

    func testDescriptionOrdersModifiersCtrlOptCmdShift() {
        let shortcut = make(control: true, command: true, shift: true, option: true, keyCode: 0, characters: "a")
        XCTAssertEqual(shortcut.description, "⌃⌥⌘⇧A")
    }

    func testCodableRoundTrip() throws {
        let shortcut = make(command: true, shift: true, keyCode: 4, characters: "h")

        let data = try JSONEncoder().encode(shortcut)
        let decoded = try JSONDecoder().decode(GlobalKeybindPreferences.self, from: data)

        XCTAssertEqual(decoded, shortcut)
    }

    // MARK: - Helpers

    private func make(
        function: Bool = false,
        control: Bool = false,
        command: Bool = false,
        shift: Bool = false,
        option: Bool = false,
        capsLock: Bool = false,
        carbonFlags: UInt32 = 0,
        keyCode: UInt32,
        characters: String?
    ) -> GlobalKeybindPreferences {
        GlobalKeybindPreferences(
            function: function, control: control, command: command,
            shift: shift, option: option, capsLock: capsLock,
            carbonFlags: carbonFlags, characters: characters, keyCode: keyCode
        )
    }
}
