import XCTest
@testable import Speakeasy

@MainActor
final class StatusBarCoordinatorTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "SpeakeasyTests.StatusBarCoordinatorTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        try await super.tearDown()
    }

    func testFullStatusBarSettingImmediatelyUpdatesApplicationActivation() {
        let settings = SettingsStore(userDefaults: defaults, persistentDomainName: suiteName)
        let applicationActivation = FakeApplicationActivationController()
        let collapseTimer = FakeAutoCollapseTimer()
        let coordinator = StatusBarCoordinator(
            settings: settings,
            applicationActivation: applicationActivation,
            collapseTimer: collapseTimer,
            statusItemAutosaveNamePrefix: "speakeasy_tests_\(UUID().uuidString)"
        )

        settings.useFullStatusBarOnExpandEnabled = true
        XCTAssertEqual(applicationActivation.appliedModes.last, .fullMenuBar)

        settings.useFullStatusBarOnExpandEnabled = false
        XCTAssertEqual(applicationActivation.appliedModes.last, .menuBarExtraOnly)

        withExtendedLifetime(coordinator) {}
    }

    func testAutoCollapseChangesUseNewPublishedValues() {
        let settings = SettingsStore(userDefaults: defaults, persistentDomainName: suiteName)
        let collapseTimer = FakeAutoCollapseTimer()
        let coordinator = StatusBarCoordinator(
            settings: settings,
            applicationActivation: FakeApplicationActivationController(),
            collapseTimer: collapseTimer,
            statusItemAutosaveNamePrefix: "speakeasy_tests_\(UUID().uuidString)"
        )

        settings.isAutoHide = false
        XCTAssertTrue(collapseTimer.startedIntervals.isEmpty)

        settings.isAutoHide = true
        XCTAssertEqual(collapseTimer.startedIntervals.last, 10)

        settings.autoHideDuration = 30
        XCTAssertEqual(collapseTimer.startedIntervals.last, 30)

        withExtendedLifetime(coordinator) {}
    }

    func testCollapsedItemsNeverUseFullMenuBarMode() {
        XCTAssertEqual(
            StatusBarCoordinator.activationMode(
                useFullStatusBarOnExpandEnabled: true,
                isCollapsed: true
            ),
            .menuBarExtraOnly
        )
    }

    func testExpandedItemsUseFullMenuBarOnlyWhenEnabled() {
        XCTAssertEqual(
            StatusBarCoordinator.activationMode(
                useFullStatusBarOnExpandEnabled: true,
                isCollapsed: false
            ),
            .fullMenuBar
        )
        XCTAssertEqual(
            StatusBarCoordinator.activationMode(
                useFullStatusBarOnExpandEnabled: false,
                isCollapsed: false
            ),
            .menuBarExtraOnly
        )
    }
}

@MainActor
private final class FakeApplicationActivationController: ApplicationActivationControlling {
    private(set) var appliedModes: [ApplicationActivationMode] = []

    func apply(_ mode: ApplicationActivationMode) {
        appliedModes.append(mode)
    }
}

@MainActor
private final class FakeAutoCollapseTimer: AutoCollapseTiming {
    private(set) var startedIntervals: [TimeInterval] = []

    func start(interval: TimeInterval, action: @escaping () -> Void) {
        startedIntervals.append(interval)
    }

    func stop() {}
}
