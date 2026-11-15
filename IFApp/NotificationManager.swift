//
//  NotificationManager.swift
//  IFApp
//

import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()

    private let foregroundPresenter = ForegroundPresenter()

    private let requests = DispatchQueue(label: "IFApp.NotificationManager.requests")

    private init() {}

    func enableForegroundPresentation() {
        UNUserNotificationCenter.current().delegate = foregroundPresenter
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
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

    private let goalReachedID = "fast_goal_reached"

    func scheduleGoalNotification(after seconds: TimeInterval) {
        cancelGoalNotification()

        let content = UNMutableNotificationContent()
        content.title = strings.Notification.goalTitle
        content.body = strings.Notification.goalBody
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: goalReachedID, content: content, trigger: trigger)

        requests.async {
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Notification scheduling error: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelGoalNotification() {
        requests.async {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [self.goalReachedID])
        }
    }

    // MARK: - Eating-window notification (one local push when the window closes)

    private let eatingEndID = "eating_window_ended"

    func scheduleEatingEndNotification(after seconds: TimeInterval) {
        cancelEatingEndNotification()

        let content = UNMutableNotificationContent()
        content.title = strings.Notification.eatingEndTitle
        content.body = strings.Notification.eatingEndBody
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: eatingEndID, content: content, trigger: trigger)

        requests.async {
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Notification scheduling error: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelEatingEndNotification() {
        requests.async {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [self.eatingEndID])
        }
    }

    func cancelDailyReminders() {
        requests.async {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["daily_noon_notification", "daily_evening_notification"])
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications cancelled")
    }
}

private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
