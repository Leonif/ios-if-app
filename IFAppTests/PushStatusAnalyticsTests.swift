//
//  PushStatusAnalyticsTests.swift
//  IFAppTests
//

import XCTest
import Redux
import UserNotifications
@testable import IFApp

final class PushStatusAnalyticsTests: XCTestCase {
    private final class TrackerSpy: AnalyticsTrackerProtocol {
        var properties: [(name: String, value: String?)] = []
        func log(_ event: AnalyticsEvent) {}
        func setUserProperty(_ value: String?, forName name: String) { properties.append((name, value)) }
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

    private let noDispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { _ in })

    func testStatusReadBecomesThePushStatusProperty() {
        let tracker = TrackerSpy()
        AnalyticsMiddleware(tracker: tracker).handle(
            action: AppLifecycleAction.pushStatusRead(label: "denied"), state: AppState(), dispatch: noDispatch)
        XCTAssertEqual(tracker.properties.map(\.name), ["push_status"])
        XCTAssertEqual(tracker.properties.map(\.value), ["denied"])
    }

    func testSyncReportsTheStatusAsAnAction() async {
        var dispatched: [Action] = []
        await SyncPushStatusThunk(notifications: Notifications(status: .authorized))
            .execute(state: AppState(), dispatch: { dispatched.append($0) })
        let labels = dispatched.compactMap { action -> String? in
            guard case let AppLifecycleAction.pushStatusRead(label) = action else { return nil }
            return label
        }
        XCTAssertEqual(labels, ["authorized"])
        XCTAssertEqual(dispatched.count, 1)
    }
}
