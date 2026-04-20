import XCTest
@testable import Hidden_Bar

@MainActor
final class SettingsStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "SpeakeasyTests.SettingsStoreTests"

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        try await super.tearDown()
    }

    func testDefaultValuesAreRegisteredOnFirstLaunch() {
        let store = SettingsStore(userDefaults: defaults)

        XCTAssertFalse(store.isAutoStart)
        XCTAssertTrue(store.isShowPreference)
        XCTAssertTrue(store.isAutoHide)
        XCTAssertEqual(store.autoHideDuration, 10.0)
        XCTAssertFalse(store.areSeparatorsHidden)
        XCTAssertFalse(store.alwaysHiddenSectionEnabled)
        XCTAssertFalse(store.useFullStatusBarOnExpandEnabled)
        XCTAssertNil(store.globalKey)
    }

    func testMutatingPublishedValuePersistsToUserDefaults() {
        let store = SettingsStore(userDefaults: defaults)

        store.isAutoHide = false
        store.autoHideDuration = 30
        store.alwaysHiddenSectionEnabled = true

        XCTAssertEqual(defaults.bool(forKey: UserDefaults.Key.isAutoHide), false)
        XCTAssertEqual(defaults.double(forKey: UserDefaults.Key.numberOfSecondForAutoHide), 30)
        XCTAssertEqual(defaults.bool(forKey: UserDefaults.Key.alwaysHiddenSectionEnabled), true)
    }

    func testRelaunchRestoresPreviouslyPersistedValues() {
        do {
            let store = SettingsStore(userDefaults: defaults)
            store.isAutoStart = true
            store.autoHideDuration = 60
        }

        let relaunch = SettingsStore(userDefaults: defaults)
        XCTAssertTrue(relaunch.isAutoStart)
        XCTAssertEqual(relaunch.autoHideDuration, 60)
    }

    func testGlobalKeyRoundTripsThroughCodable() {
        let store = SettingsStore(userDefaults: defaults)
        let shortcut = GlobalKeybindPreferences(
            function: false, control: false, command: true, shift: true, option: false, capsLock: false,
            carbonFlags: 0, characters: "h", keyCode: 4
        )

        store.globalKey = shortcut

        let relaunch = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(relaunch.globalKey, shortcut)
    }

    func testClearingGlobalKeyRemovesItFromDefaults() {
        let store = SettingsStore(userDefaults: defaults)
        store.globalKey = GlobalKeybindPreferences(
            function: false, control: false, command: true, shift: false, option: false, capsLock: false,
            carbonFlags: 0, characters: "k", keyCode: 40
        )
        store.globalKey = nil

        XCTAssertNil(defaults.value(forKey: UserDefaults.Key.globalKey))
    }

    func testLegacyIsShowPreferencesKeyMigratesOnLaunch() {
        defaults.set(false, forKey: UserDefaults.Key.Legacy.isShowPreference)

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertFalse(store.isShowPreference)
        XCTAssertNil(defaults.object(forKey: UserDefaults.Key.Legacy.isShowPreference))
        XCTAssertEqual(defaults.bool(forKey: UserDefaults.Key.isShowPreference), false)
    }

    func testCurrentKeyTakesPrecedenceOverLegacyKey() {
        defaults.set(false, forKey: UserDefaults.Key.Legacy.isShowPreference)
        defaults.set(true, forKey: UserDefaults.Key.isShowPreference)

        let store = SettingsStore(userDefaults: defaults)

        XCTAssertTrue(store.isShowPreference)
    }
}
