//
//  SyncPushStatusThunk.swift
//  IFApp
//

import Foundation
import Redux
import UserNotifications

struct SyncPushStatusThunk: Thunk {
    private let notifications: NotificationSchedulerProtocol

    init(notifications: NotificationSchedulerProtocol = container.inject()) {
        self.notifications = notifications
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let status = await notifications.authorizationStatus()
        dispatch(AppLifecycleAction.pushStatusRead(label: Self.label(for: status)))
    }

    @discardableResult
    static func requestIfUndetermined(notifications: NotificationSchedulerProtocol,
                                      dispatch: @escaping (Action) -> Void) async -> Bool {
        guard !promptSuppressed else { return false }
        guard await notifications.authorizationStatus() == .notDetermined else { return false }

        await notifications.requestAuthorization()

        let status = await notifications.authorizationStatus()
        dispatch(AppLifecycleAction.pushStatusRead(label: label(for: status)))
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
