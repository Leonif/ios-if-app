//
//  NotificationRepository.swift
//  IFApp
//
//  Thin wrapper over NotificationManager so thunks depend on a protocol, not a singleton.
//

import Foundation

protocol NotificationRepositoryProtocol {
    func requestAuthorization()
    /// One-time cleanup of the legacy fixed daily reminders on existing installs.
    func removeLegacyDailyReminders()
    /// Schedule (replacing any existing) the goal-reached push `seconds` from now.
    func scheduleGoalNotification(after seconds: TimeInterval)
    func cancelGoalNotification()
}

struct NotificationRepository: NotificationRepositoryProtocol {
    func requestAuthorization() {
        NotificationManager.shared.requestAuthorization()
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
}
