import XCTest
@testable import Speakeasy

@MainActor
final class LaunchAtLoginControllerTests: XCTestCase {

    func testInitialStatusComesFromService() {
        let service = FakeLaunchAtLoginService(status: .enabled)

        let controller = LaunchAtLoginController(service: service)

        XCTAssertEqual(controller.status, .enabled)
        XCTAssertTrue(controller.isEnabled)
    }

    func testEnablingDelegatesToServiceAndRefreshesStatus() {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.statusAfterChange = .enabled
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        XCTAssertEqual(service.requestedValues, [true])
        XCTAssertEqual(controller.status, .enabled)
        XCTAssertNil(controller.errorMessage)
    }

    func testApprovalRequirementRemainsAuthoritative() {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.statusAfterChange = .requiresApproval
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        XCTAssertEqual(controller.status, .requiresApproval)
        XCTAssertFalse(controller.isEnabled)
    }

    func testFailureIsExposedWithoutOverridingServiceStatus() {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.error = TestError.registrationFailed
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        XCTAssertEqual(controller.status, .disabled)
        XCTAssertEqual(controller.errorMessage, TestError.registrationFailed.localizedDescription)
    }

    func testRefreshPicksUpExternalChangesAndClearsErrors() {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.error = TestError.registrationFailed
        let controller = LaunchAtLoginController(service: service)
        controller.setEnabled(true)
        service.error = nil
        service.status = .enabled

        controller.refresh()

        XCTAssertEqual(controller.status, .enabled)
        XCTAssertNil(controller.errorMessage)
    }

    func testOpeningSystemSettingsDelegatesToService() {
        let service = FakeLaunchAtLoginService(status: .requiresApproval)
        let controller = LaunchAtLoginController(service: service)

        controller.openSystemSettings()

        XCTAssertEqual(service.openSystemSettingsCallCount, 1)
    }
}

@MainActor
private final class FakeLaunchAtLoginService: LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus
    var statusAfterChange: LaunchAtLoginStatus?
    var error: Error?
    private(set) var requestedValues: [Bool] = []
    private(set) var openSystemSettingsCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func setEnabled(_ isEnabled: Bool) throws {
        requestedValues.append(isEnabled)
        if let error {
            throw error
        }
        if let statusAfterChange {
            status = statusAfterChange
        }
    }

    func openSystemSettings() {
        openSystemSettingsCallCount += 1
    }
}

private enum TestError: LocalizedError {
    case registrationFailed

    var errorDescription: String? {
        "Registration failed"
    }
}
