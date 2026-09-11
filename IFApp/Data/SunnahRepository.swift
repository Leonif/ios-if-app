import Foundation
import UserNotifications

protocol SunnahRepositoryProtocol {
    func load() -> SunnahSettings
    func save(_ settings: SunnahSettings)
    func replace(_ reminders: [SunnahSchedule.Reminder]) async -> Bool
}

struct SunnahRepository: SunnahRepositoryProtocol {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private let key = "sunnah.reminders.v1"
    func load() -> SunnahSettings {
        guard let data = defaults.data(forKey: key),
              var settings = try? JSONDecoder().decode(SunnahSettings.self, from: data) else {
            return SunnahSettings()
        }
        settings.minuteOfDay = min(1439, max(0, settings.minuteOfDay))
        return settings
    }
    func save(_ settings: SunnahSettings) {
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: key) }
    }
    func replace(_ reminders: [SunnahSchedule.Reminder]) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.filter { $0.identifier.hasPrefix("sunnah.") }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ours)
        // Leave room for unrelated notifications and the timer's two replaceable pushes.
        let others = pending.count - ours.count
        let capacity = max(0, min(48, 60 - others))
        guard reminders.count <= capacity else { return false }
        for (index, reminder) in reminders.enumerated() {
            if Task.isCancelled { return false }
            let content = UNMutableNotificationContent()
            content.title = SunnahStrings.title
            content.body = SunnahStrings.notification
            content.sound = .default
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            let request = UNNotificationRequest(identifier: "sunnah.\(index)", content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
            do { try await center.add(request) }
            catch {
                center.removePendingNotificationRequests(withIdentifiers: (0..<reminders.count).map { "sunnah.\($0)" })
                return false
            }
        }
        return true
    }
}
