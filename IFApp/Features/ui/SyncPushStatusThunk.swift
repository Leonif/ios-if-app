//
//  SyncPushStatusThunk.swift
//  IFApp
//
//  Records whether notifications are enabled as a user property. The review
//  prompt hangs off the goal push, so the funnel is unreadable without knowing
//  who could even receive it. Runs once per cold launch (from IFAppApp.init),
//  so a settings change is only picked up on the next app start.
//

import Redux
import UserNotifications

struct SyncPushStatusThunk: Thunk {
    private let notifications: NotificationRepositoryProtocol
    private let analytics: AnalyticsRepositoryProtocol

    init(notifications: NotificationRepositoryProtocol = container.inject(),
         analytics: AnalyticsRepositoryProtocol = container.inject()) {
        self.notifications = notifications
        self.analytics = analytics
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let status = await notifications.authorizationStatus()
        analytics.setUserProperty(Self.label(for: status), forName: "push_status")
    }

    private static func label(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .notDetermined: return "notDetermined"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown"
        }
    }
}
