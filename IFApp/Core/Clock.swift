//
//  Clock.swift
//  IFApp
//

import Foundation

enum Clock {
    static func now() -> Date { Date() }

    static func minuteOfDay(_ date: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = gregorian
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func dayKey(_ date: Date = Date()) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func goalDayKey(fastStart: Double, goalHours: Double) -> String {
        dayKey(Date(timeIntervalSince1970: fastStart + goalHours * 3600))
    }

    static func daysBetween(_ earlier: String, _ later: String) -> Int? {
        guard let e = dayKeyFormatter.date(from: earlier),
              let l = dayKeyFormatter.date(from: later) else { return nil }
        return gregorian.dateComponents([.day], from: e, to: l).day
    }

    static func isDayBefore(_ earlier: String, _ later: String) -> Bool {
        daysBetween(earlier, later) == 1
    }

    static func nextDay(_ dayKey: String) -> String? {
        guard let d = dayKeyFormatter.date(from: dayKey),
              let next = gregorian.date(byAdding: .day, value: 1, to: d) else { return nil }
        return dayKeyFormatter.string(from: next)
    }

    static func date(forDayKey dayKey: String) -> Date? {
        dayKeyFormatter.date(from: dayKey)
    }

    static func monthKey(ofDay dayKey: String) -> String {
        String(dayKey.prefix(7))
    }
}
