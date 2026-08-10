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

    /// The local day a fast's goal counts toward: the day the goal is *crossed*
    /// (`start + goal`), never the day someone happened to notice it. The single
    /// definition — the live streak (`CelebrateGoalThunk`) and a stored fast
    /// (`FastRecord.goalDayKey`) both read it from here, so a back-dated fast whose
    /// goal landed before midnight credits the same day on both screens.
    static func goalDayKey(fastStart: Double, goalHours: Double) -> String {
        dayKey(Date(timeIntervalSince1970: fastStart + goalHours * 3600))
    }

    /// Whole calendar days from `earlier` to `later` (both day keys); nil if either
    /// is not one. Negative when `later` is the earlier of the two.
    ///
    /// Days, not hours: a gap measured in seconds and divided by 86400 gets a DST
    /// change wrong twice a year, and "the day after" has to mean the same thing on
    /// those two days as on the other 363.
    static func daysBetween(_ earlier: String, _ later: String) -> Int? {
        guard let e = dayKeyFormatter.date(from: earlier),
              let l = dayKeyFormatter.date(from: later) else { return nil }
        return Calendar.current.dateComponents([.day], from: e, to: l).day
    }

    /// True if `earlier` names the calendar day right before `later` (both day keys).
    static func isDayBefore(_ earlier: String, _ later: String) -> Bool {
        daysBetween(earlier, later) == 1
    }

    /// The day key of the calendar day right after `dayKey`; nil if it is not one.
    /// Month and year ends are the calendar's business, not string arithmetic's.
    static func nextDay(_ dayKey: String) -> String? {
        guard let d = dayKeyFormatter.date(from: dayKey),
              let next = Calendar.current.date(byAdding: .day, value: 1, to: d) else { return nil }
        return dayKeyFormatter.string(from: next)
    }

    /// The calendar month a day key belongs to, as "yyyy-MM". Taken off the key
    /// rather than re-derived from a date: the key's shape is fixed by the formatter
    /// above, and a second parse could only disagree with it.
    static func monthKey(ofDay dayKey: String) -> String {
        String(dayKey.prefix(7))
    }
}
