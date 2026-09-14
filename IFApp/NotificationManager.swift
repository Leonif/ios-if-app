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

    /// Held here because `UNUserNotificationCenter.delegate` is weak: a presenter
    /// created at the call site would be released at once and the center would go
    /// back to swallowing foreground deliveries without a word.
    private let foregroundPresenter = ForegroundPresenter()

    private init() {}

    /// Lets local pushes show while the app is open. Without a center delegate iOS
    /// delivers a notification whose moment arrives in the foreground to nobody — the
    /// eating-window-closed and goal-reached pushes simply never appeared for someone
    /// sitting on the screen they are about. Must run before launch finishes, since a
    /// notification can be due the instant the app opens.
    func enableForegroundPresentation() {
        UNUserNotificationCenter.current().delegate = foregroundPresenter
    }

    /// Shows the system permission dialog and waits for the user's answer. The
    /// caller must await it: reading `authorizationStatus()` before it returns
    /// records the state from before the dialog, not the user's decision.
    /// A thrown error means "not granted" — the read-back of the real status is
    /// what gets recorded, never this flag.
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// The current notification authorization status (user may change it in Settings).
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

    // MARK: - Eating-window notification (one local push when the window closes)

    /// A single, replaceable local notification fired when the eating window closes.
    private let eatingEndID = "eating_window_ended"

    /// Schedules the eating-window-closed notification `seconds` from now, replacing
    /// any previously scheduled one. Fires even if the app is backgrounded or killed.
    func scheduleEatingEndNotification(after seconds: TimeInterval) {
        cancelEatingEndNotification()

        let content = UNMutableNotificationContent()
        content.title = strings.Notification.eatingEndTitle
        content.body = strings.Notification.eatingEndBody
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: eatingEndID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }

    func cancelEatingEndNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [eatingEndID])
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

/// Presents every local push the app schedules — goal reached, eating window closed,
/// Sunnah reminders — the same way in the foreground as in the background: banner,
/// Notification Center entry and sound. Nothing is filtered by identifier: each of
/// them is scheduled for a moment the user asked to be told about, and being inside
/// the app at that moment is not a reason to stay silent.
///
/// `didReceive` is deliberately not implemented: a tap keeps the system default of
/// opening the app, exactly as before a delegate existed.
private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
