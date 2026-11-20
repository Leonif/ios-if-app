//
//  NotificationMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
import UserNotifications
@testable import IFApp

final class NotificationMiddlewareTests: XCTestCase {
    private struct Notifications: NotificationSchedulerProtocol {
        func enableForegroundPresentation() {}
        func requestAuthorization() async -> Bool { false }
        func authorizationStatus() async -> UNAuthorizationStatus { .notDetermined }
        func removeLegacyDailyReminders() {}
        func scheduleGoalNotification(after seconds: TimeInterval) {}
        func cancelGoalNotification() {}
        func scheduleEatingEndNotification(after seconds: TimeInterval) {}
        func cancelEatingEndNotification() {}
    }

    private final class Box { var thunks: [Thunk] = [] }

    private func thunks(after action: Action) -> [Thunk] {
        let box = Box()
        NotificationMiddleware(repo: Notifications()).handle(
            action: action, state: AppState(),
            dispatch: DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { box.thunks.append($0) }))
        return box.thunks
    }

    func testLaunchClearsLegacyRemindersAndReportsPushStatus() {
        let thunks = thunks(after: AppLifecycleAction.appOpened)
        XCTAssertEqual(thunks.count, 2)
        XCTAssertTrue(thunks.contains { $0 is ScheduleNotificationsThunk })
        XCTAssertTrue(thunks.contains { $0 is SyncPushStatusThunk })
    }

    func testOtherLifecycleActionsRunNothing() {
        for action in [AppLifecycleAction.appBecameActive, .pushAuthorizationResolved] {
            XCTAssertTrue(thunks(after: action).isEmpty)
        }
    }
}
