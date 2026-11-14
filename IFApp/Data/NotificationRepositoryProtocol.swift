//
//  NotificationRepositoryProtocol.swift
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
