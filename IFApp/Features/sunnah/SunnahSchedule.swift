//
//  SunnahSchedule.swift
//  IFApp
//

import Foundation

enum SunnahSchedule {
    struct Reminder: Equatable, Sendable { let fastDate: Date; let fireDate: Date }

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
