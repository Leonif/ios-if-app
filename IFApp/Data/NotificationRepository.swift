//
//  NotificationRepository.swift
//  IFApp
//

import Foundation
import UserNotifications

protocol NotificationRepositoryProtocol {
    func enableForegroundPresentation()
    @discardableResult
    func requestAuthorization() async -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    func removeLegacyDailyReminders()
    func scheduleGoalNotification(after seconds: TimeInterval)
    func cancelGoalNotification()
    func scheduleEatingEndNotification(after seconds: TimeInterval)
    func cancelEatingEndNotification()
}

struct NotificationRepository: NotificationRepositoryProtocol {
    func enableForegroundPresentation() {
        NotificationManager.shared.enableForegroundPresentation()
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        await NotificationManager.shared.requestAuthorization()
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
