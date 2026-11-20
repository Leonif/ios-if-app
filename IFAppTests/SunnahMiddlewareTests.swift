import XCTest
import Redux
import UserNotifications
import UIKit
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
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            await recorder.append(reminders.count)
            return true
        }
    }
    private struct Notifications: NotificationSchedulerProtocol {
        let status: UNAuthorizationStatus
        func enableForegroundPresentation() {}
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
        let dates = Recorder()
        let dispatch = DispatchFunction(dispatchAction: { action in
            if case SunnahAction.deliveryUpdated(.denied, let upcoming) = action {
                Task { await dates.append(upcoming.count); finished.fulfill() }
            }
        }, dispatchThunk: { _ in })
        var enabled = AppState()
        enabled.sunnahState.settings.weekly = true
        middleware.handle(action: SunnahAction.refresh, state: enabled, dispatch: dispatch)
        await fulfillment(of: [finished], timeout: 3)
        let counts = await repository.recorder.values()
        XCTAssertEqual(counts, [0])
        let delivered = await dates.values()
        XCTAssertEqual(delivered, [0])
        withExtendedLifetime(middleware) {}
    }

    func testGrantedPermissionStillDeliversUpcomingDates() async {
        let finished = expectation(description: "scheduled delivered")
        let repository = Repository()
        let middleware = SunnahMiddleware(repository: repository, notifications: Notifications(status: .authorized))
        let dates = Recorder()
        let dispatch = DispatchFunction(dispatchAction: { action in
            if case SunnahAction.deliveryUpdated(.scheduled, let upcoming) = action {
                Task { await dates.append(upcoming.count); finished.fulfill() }
            }
        }, dispatchThunk: { _ in })
        var enabled = AppState()
        enabled.sunnahState.settings.weekly = true
        middleware.handle(action: SunnahAction.refresh, state: enabled, dispatch: dispatch)
        await fulfillment(of: [finished], timeout: 3)
        let delivered = await dates.values()
        XCTAssertEqual(delivered, [3])
        withExtendedLifetime(middleware) {}
    }

    func testSettingsTapOpensTheSystemSettingsAndSchedulesNothing() async throws {
        final class Box { var actions: [Action] = []; var thunks: [Thunk] = [] }
        let box = Box()
        let repository = Repository()
        let middleware = SunnahMiddleware(repository: repository, notifications: Notifications(status: .authorized))
        let url = try XCTUnwrap(URL(string: UIApplication.openSettingsURLString))
        var enabled = AppState()
        enabled.sunnahState.settings.weekly = true
        middleware.handle(action: SunnahAction.systemSettingsTapped(url: url), state: enabled,
                          dispatch: DispatchFunction(dispatchAction: { box.actions.append($0) },
                                                     dispatchThunk: { box.thunks.append($0) }))
        XCTAssertEqual(box.thunks.count, 1)
        let link = try XCTUnwrap(box.thunks.first as? OpenExternalLinkThunk)
        XCTAssertEqual(Mirror(reflecting: link).descendant("url") as? URL, url)
        try await Task.sleep(nanoseconds: 200_000_000)
        let counts = await repository.recorder.values()
        XCTAssertTrue(counts.isEmpty)
        XCTAssertTrue(box.actions.isEmpty)
        withExtendedLifetime(middleware) {}
    }
}
