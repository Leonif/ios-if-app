//
//  NotificationManager.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 30.04.2025.
//

import UserNotifications

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

    func scheduleDailyNoonNotification() {
        var dateComponents = DateComponents()
        dateComponents.hour = 12
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.reminderTitle
        content.body = L10n.Notification.reminderBody
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily_noon_notification",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("\(L10n.Notification.errorScheduling): \(error.localizedDescription)")
            } else {
                print(L10n.Notification.scheduledMessage)
            }
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print(L10n.Notification.allCancelled)
    }
}
