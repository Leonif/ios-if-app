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
                print("Notification scheduling error: \(error.localizedDescription)")
            } else {
                print("Уведомление запланировано через \(seconds) секунд.")
            }
        }
    }

    // MARK: - Fast-goal notification (one local push at goal time)

    /// A single, replaceable local notification fired when the fast reaches its goal.
    private let goalReachedID = "fast_goal_reached"

    /// Schedules the goal-reached notification `seconds` from now, replacing any
    /// previously scheduled one. Fires even if the app is backgrounded or killed.
    func scheduleGoalNotification(after seconds: TimeInterval) {
        cancelGoalNotification()

        let content = UNMutableNotificationContent()
        content.title = strings.Notification.goalTitle
        content.body = strings.Notification.goalBody
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: goalReachedID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }

    func cancelGoalNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [goalReachedID])
    }

    /// Removes the legacy fixed daily reminders (noon/evening) left scheduled on
    /// existing installs after dropping that feature.
    func cancelDailyReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_noon_notification", "daily_evening_notification"])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications cancelled")
    }
}
