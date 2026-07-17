//
//  NotificationRepository.swift
//  IFApp
//
//  Thin wrapper over NotificationManager so thunks depend on a protocol, not a singleton.
//

import Foundation
import UserNotifications

protocol NotificationRepositoryProtocol {
    func requestAuthorization()
    /// The current notification authorization status.
    func authorizationStatus() async -> UNAuthorizationStatus
    /// One-time cleanup of the legacy fixed daily reminders on existing installs.
    func removeLegacyDailyReminders()
    /// Schedule (replacing any existing) the goal-reached push `seconds` from now.
    func scheduleGoalNotification(after seconds: TimeInterval)
    func cancelGoalNotification()
    /// Schedule (replacing any existing) the eating-window-closed push `seconds` from now.
    func scheduleEatingEndNotification(after seconds: TimeInterval)
    func cancelEatingEndNotification()
}

struct NotificationRepository: NotificationRepositoryProtocol {
    func requestAuthorization() {
        NotificationManager.shared.requestAuthorization()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await NotificationManager.shared.authorizationStatus()
    }

    func removeLegacyDailyReminders() {
        NotificationManager.shared.cancelDailyReminders()
    }

    func scheduleGoalNotification(after seconds: TimeInterval) {
        NotificationManager.shared.scheduleGoalNotification(after: seconds)
    }

    func cancelGoalNotification() {
        NotificationManager.shared.cancelGoalNotification()
    }

    func scheduleEatingEndNotification(after seconds: TimeInterval) {
        NotificationManager.shared.scheduleEatingEndNotification(after: seconds)
    }

    func cancelEatingEndNotification() {
        NotificationManager.shared.cancelEatingEndNotification()
    }
}
