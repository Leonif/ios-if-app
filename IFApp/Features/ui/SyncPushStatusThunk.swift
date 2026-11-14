//
//  SyncPushStatusThunk.swift
//  IFApp
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

    private static var promptSuppressed: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-suppressPushPrompt")
        #else
        return false
        #endif
    }

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
