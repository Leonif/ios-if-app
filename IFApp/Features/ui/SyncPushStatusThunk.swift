//
//  SyncPushStatusThunk.swift
//  IFApp
//
//  Records whether notifications are enabled as a user property. The review
//  prompt hangs off the goal push, so the funnel is unreadable without knowing
//  who could even receive it. Runs once per cold launch (from IFAppApp.init):
//  nothing is asked at launch any more, so this just reports the current state
//  and picks up permission changes made in iOS Settings between sessions.
//

import Foundation
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

    /// The one place a permission ask happens. Asks only while the status is
    /// `notDetermined`: the system shot is one-time, and on `denied` a repeat call
    /// shows nothing anyway. `push_status` is written from the status read back
    /// *after* the answer, so it reflects what the user actually chose (which may be
    /// partial), not what we asked for; then `pushAuthorizationResolved` lets the
    /// goal/eating pushes that were refused before the grant reschedule. Shared by
    /// `StartFastThunk` and `SunnahMiddleware` so both entry points leave the
    /// property in the same state — while the Sunnah path had its own copy, a grant
    /// through it left `push_status` at `notDetermined` until the next cold start.
    /// Returns whether the dialog was shown.
    @discardableResult
    static func requestIfUndetermined(notifications: NotificationRepositoryProtocol,
                                      analytics: AnalyticsRepositoryProtocol,
                                      dispatch: @escaping (Action) -> Void) async -> Bool {
        guard !promptSuppressed else { return false }
        guard await notifications.authorizationStatus() == .notDetermined else { return false }

        await notifications.requestAuthorization()

        let status = await notifications.authorizationStatus()
        analytics.setUserProperty(label(for: status), forName: "push_status")
        dispatch(AppLifecycleAction.pushAuthorizationResolved)
        return true
    }

    /// UI tests drive Start fast, and the system dialog covers the screen and breaks
    /// the flow. `-suppressPushPrompt` skips the ask; DEBUG-only, like `UITestSeed`.
    private static var promptSuppressed: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-suppressPushPrompt")
        #else
        return false
        #endif
    }

    /// The `push_status` value for a status.
    static func label(for status: UNAuthorizationStatus) -> String {
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
