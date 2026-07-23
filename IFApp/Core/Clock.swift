//
//  Clock.swift
//  IFApp
//
//  The one place that reads wall-clock time for thunks (kept out of reducers/views).
//

import Foundation

enum Clock {
    static func now() -> Date { Date() }

    static func minuteOfDay(_ date: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    // Streak day keys: a local-calendar date as "yyyy-MM-dd". String-keyed so the
    // persisted value stays readable and timezone shifts don't reinterpret it.
    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// "2026-07-23" for the local calendar day containing `date`.
    static func dayKey(_ date: Date = Date()) -> String {
        dayKeyFormatter.string(from: date)
    }

    /// True if `earlier` names the calendar day right before `later` (both day keys).
    static func isDayBefore(_ earlier: String, _ later: String) -> Bool {
        guard let e = dayKeyFormatter.date(from: earlier),
              let l = dayKeyFormatter.date(from: later) else { return false }
        return Calendar.current.dateComponents([.day], from: e, to: l).day == 1
    }
}
