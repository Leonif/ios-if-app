//
//  NotificationManager.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 30.04.2025.
//

import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Ошибка при запросе разрешения на уведомления: \(error.localizedDescription)")
            }
            print("Уведомления разрешены: \(granted)")
        }
    }

    func sendNotification(for stage: TimeStage) {
        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.phaseTitle(stage.displayString)
        content.body = stage.description
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("\(L10n.Notification.errorScheduling): \(error.localizedDescription)")
            } else {
                print(L10n.Notification.sentMessage)
            }
        }
    }

    func scheduleNotification(after seconds: TimeInterval, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("\(L10n.Notification.errorScheduling): \(error.localizedDescription)")
            } else {
                print("Уведомление запланировано через \(seconds) секунд.")
            }
        }
    }

    // MARK: - Общий метод для планирования ежедневных уведомлений
    private func scheduleDailyNotification(
        hour: Int,
        minute: Int = 0,
        identifier: String,
        title: String,
        body: String,
        successMessage: String
    ) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("\(L10n.Notification.errorScheduling): \(error.localizedDescription)")
            } else {
                print(successMessage)
            }
        }
    }

    func scheduleDailyNoonNotification() {
        scheduleDailyNotification(
            hour: 12,
            identifier: "daily_noon_notification",
            title: L10n.Notification.reminderTitle,
            body: L10n.Notification.reminderBody,
            successMessage: L10n.Notification.scheduledMessage
        )
    }

    func scheduleDailyEveningNotification() {
        scheduleDailyNotification(
            hour: 17,
            identifier: "daily_evening_notification",
            title: L10n.Notification.eveningTitle,
            body: L10n.Notification.eveningBody,
            successMessage: L10n.Notification.eveningScheduledMessage
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print(L10n.Notification.allCancelled)
    }
}
