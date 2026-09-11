import Foundation
import Redux

struct SunnahSettings: Codable, Equatable, Sendable {
    var weekly = false
    var whiteDays = false
    var minuteOfDay = 20 * 60
    var enabled: Bool { weekly || whiteDays }

    /// Which schedule is armed, as the GA4 `mode` dimension. A fixed ASCII list, never
    /// a displayed label: the switches are localized in ten languages and a dimension
    /// carrying their text could not be grouped.
    var analyticsMode: String {
        switch (weekly, whiteDays) {
        case (true, true): return "both"
        case (true, false): return "weekly"
        case (false, true): return "white_days"
        case (false, false): return "off"
        }
    }

    /// The domain clamp, and the only one: a reminder time is a minute of a civil day.
    /// Both roads a value enters by - the picker (via the reducer) and the stored
    /// blob (via the repository) - pass through here.
    static func clamped(minuteOfDay: Int) -> Int { min(1439, max(0, minuteOfDay)) }
}

struct SunnahState: Equatable, Sendable {
    enum Delivery: Equatable, Sendable {
        case off, checking, scheduled, denied, failed

        /// Disabled reminders are `.off` and nothing else, whether the schedule has
        /// run or not - one definition for the reducer's provisional value and the
        /// middleware's settled one.
        static func resolve(enabled: Bool, otherwise: Delivery) -> Delivery { enabled ? otherwise : .off }
    }
    var settings = SunnahSettings()
    var delivery: Delivery = .off
    var upcoming: [Date] = []
}

enum SunnahAction: Action {
    case settingsChanged(SunnahSettings)
    case refresh
    case deliveryUpdated(SunnahState.Delivery, dates: [Date])
}

func sunnahReducer(state: SunnahState, action: Action) -> SunnahState {
    guard let action = action as? SunnahAction else { return state }
    var next = state
    switch action {
    case .settingsChanged(var settings):
        settings.minuteOfDay = SunnahSettings.clamped(minuteOfDay: settings.minuteOfDay)
        next.settings = settings
        next.delivery = .resolve(enabled: settings.enabled, otherwise: .checking)
    case .refresh: break
    case .deliveryUpdated(let delivery, let dates):
        next.delivery = delivery
        next.upcoming = dates
    }
    return next
}

/// Civil-date reminders, not a sunrise/sunset calculation. All time inputs are explicit.
enum SunnahSchedule {
    struct Reminder: Equatable, Sendable { let fastDate: Date; let fireDate: Date }

    /// How many reminders are ever scheduled at once; the repository reserves the
    /// same room in the pending-notification budget.
    static let maxReminders = 48

    static func reminders(settings: SunnahSettings, now: Date, timeZone: TimeZone,
                          limit: Int = maxReminders) -> [Reminder] {
        guard settings.enabled, limit > 0 else { return [] }
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = timeZone
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = timeZone
        let today = civil.startOfDay(for: now)
        var result: [Reminder] = []
        for offset in 1...120 {
            guard let day = civil.date(byAdding: .day, value: offset, to: today),
                  let noon = civil.date(bySettingHour: 12, minute: 0, second: 0, of: day) else { continue }
            let h = hijri.dateComponents([.month, .day], from: noon)
            guard let month = h.month, let lunarDay = h.day else { continue }
            // Ramadan is not a voluntary weekly schedule. Never suggest Eid or Tashriq.
            if month == 9 || (month == 10 && lunarDay == 1) ||
                (month == 12 && (10...13).contains(lunarDay)) { continue }
            let weekday = civil.component(.weekday, from: day)
            guard (settings.weekly && [2, 5].contains(weekday)) ||
                    (settings.whiteDays && (13...15).contains(lunarDay)) else { continue }
            guard let eve = civil.date(byAdding: .day, value: -1, to: day),
                  let fire = civil.date(bySettingHour: settings.minuteOfDay / 60,
                                        minute: settings.minuteOfDay % 60, second: 0, of: eve),
                  fire > now else { continue }
            result.append(Reminder(fastDate: day, fireDate: fire))
            if result.count == limit { break }
        }
        return result
    }
}
