import XCTest
import Redux
import UserNotifications
@testable import IFApp

final class SunnahMiddlewareTests: XCTestCase {
    private actor Recorder {
        var counts: [Int] = []
        func append(_ count: Int) { counts.append(count) }
        func values() -> [Int] { counts }
    }
    private final class Repository: SunnahRepositoryProtocol {
        let recorder = Recorder()
        let began: XCTestExpectation?
        init(began: XCTestExpectation? = nil) { self.began = began }
        func load() -> SunnahSettings { .init() }
        func save(_ settings: SunnahSettings) {}
        func replace(_ reminders: [SunnahSchedule.Reminder]) async -> Bool {
            if !reminders.isEmpty {
                began?.fulfill()
                // Model an in-flight write: cancellation alone does not undo it.
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            await recorder.append(reminders.count)
            return true
        }
    }
    private struct Notifications: NotificationRepositoryProtocol {
        let status: UNAuthorizationStatus
        func requestAuthorization() async -> Bool { false }
        func authorizationStatus() async -> UNAuthorizationStatus { status }
        func removeLegacyDailyReminders() {}
        func scheduleGoalNotification(after seconds: TimeInterval) {}
        func cancelGoalNotification() {}
        func scheduleEatingEndNotification(after seconds: TimeInterval) {}
        func cancelEatingEndNotification() {}
    }

    func testDisablingWaitsForAnOlderWriteThenClearsIt() async {
        let began = expectation(description: "first write began")
        let finished = expectation(description: "off delivered")
        let repository = Repository(began: began)
        let middleware = SunnahMiddleware(repository: repository, notifications: Notifications(status: .authorized))
        let dispatch = DispatchFunction(dispatchAction: { action in
            if case SunnahAction.deliveryUpdated(.off, _) = action { finished.fulfill() }
        }, dispatchThunk: { _ in })
        var enabled = AppState()
        enabled.sunnahState.settings.weekly = true
        middleware.handle(action: SunnahAction.refresh, state: enabled, dispatch: dispatch)
        await fulfillment(of: [began], timeout: 3)
        let disabled = AppState()
        middleware.handle(action: SunnahAction.settingsChanged(.init()), state: disabled, dispatch: dispatch)
        await fulfillment(of: [finished], timeout: 3)
        let counts = await repository.recorder.values()
        XCTAssertEqual(counts.count, 2)
        XCTAssertGreaterThan(counts[0], 0)
        XCTAssertEqual(counts.last, 0)
        withExtendedLifetime(middleware) {}
    }

    func testDeniedPermissionClearsRequestsAndReportsDenied() async {
        let finished = expectation(description: "denied delivered")
        let repository = Repository()
        let middleware = SunnahMiddleware(repository: repository, notifications: Notifications(status: .denied))
        let dispatch = DispatchFunction(dispatchAction: { action in
            if case SunnahAction.deliveryUpdated(.denied, _) = action { finished.fulfill() }
        }, dispatchThunk: { _ in })
        var enabled = AppState()
        enabled.sunnahState.settings.weekly = true
        middleware.handle(action: SunnahAction.refresh, state: enabled, dispatch: dispatch)
        await fulfillment(of: [finished], timeout: 3)
        let counts = await repository.recorder.values()
        XCTAssertEqual(counts, [0])
        withExtendedLifetime(middleware) {}
    }
}
