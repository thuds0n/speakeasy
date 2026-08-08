import XCTest
@testable import Speakeasy

/// Verifies that the `HotKeyServicing` protocol abstracts the hotkey callback flow so tests and
/// callers can substitute a fake. Does not exercise the real Carbon hotkey registration, which is
/// the responsibility of the `HotKey` third-party package.
@MainActor
final class HotKeyServicingTests: XCTestCase {

    func testFakeServiceRoutesCallbacksThroughOnKeyDown() {
        let fake = FakeHotKeyService()
        let expectation = expectation(description: "onKeyDown invoked")
        fake.onKeyDown = { expectation.fulfill() }

        fake.simulateKeyDown()

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateShortcutRecordsLastValue() {
        let fake = FakeHotKeyService()
        let shortcut = GlobalKeybindPreferences(
            function: false, control: false, command: true, shift: false, option: false, capsLock: false,
            carbonFlags: 0, characters: "k", keyCode: 40
        )

        fake.updateShortcut(shortcut)
        XCTAssertEqual(fake.lastShortcut, shortcut)

        fake.updateShortcut(nil)
        XCTAssertNil(fake.lastShortcut)
    }
}

@MainActor
private final class FakeHotKeyService: HotKeyServicing {
    var onKeyDown: (() -> Void)?
    private(set) var lastShortcut: GlobalKeybindPreferences?

    func updateShortcut(_ shortcut: GlobalKeybindPreferences?) {
        lastShortcut = shortcut
    }

    func simulateKeyDown() {
        onKeyDown?()
    }
}
