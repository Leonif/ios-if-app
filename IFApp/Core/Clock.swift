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

    /// The calendar the app counts days in: Gregorian, in the device's time zone.
    ///
    /// Named once and reused rather than written per call site, because the
    /// alternative is `Calendar.current` — which on an Arabic device is
    /// `islamic-umm-al-qura`. Day arithmetic survives that; month arithmetic does
    /// not. The history grouped its rows by `Calendar.current`'s month and then
    /// printed the result with the Gregorian formatter of `Locale.latinDigits`, so a
    /// September fast sat under "أغسطس 2026": the header named the Gregorian month
    /// the *Hijri* month happened to begin in (SU-6).
    ///
    /// Same rule as `Locale.latinDigits` and for the same reason, one layer down —
    /// every day key, streak and seven-day dot in the app is a Gregorian day, so
    /// anything that buckets those days has to agree with them.
    ///
    /// Computed, not stored: a stored `Calendar` freezes the time zone it was built
    /// in, so every caller that asks per use — the history's grouping is asked again
    /// on each render — follows a zone change. `dayKeyFormatter` below does not: it
    /// is a `static let` and freezes its zone at first use, exactly as it did when
    /// the calendar was written inline there. That is the formatter's own question,
    /// not one this accessor answers for it.
    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    // Streak day keys: a local-calendar date as "yyyy-MM-dd". String-keyed so the
    // persisted value stays readable and timezone shifts don't reinterpret it.
    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = gregorian
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
        return gregorian.dateComponents([.day], from: e, to: l).day
    }

    /// True if `earlier` names the calendar day right before `later` (both day keys).
    static func isDayBefore(_ earlier: String, _ later: String) -> Bool {
        daysBetween(earlier, later) == 1
    }

    /// The day key of the calendar day right after `dayKey`; nil if it is not one.
    /// Month and year ends are the calendar's business, not string arithmetic's.
    static func nextDay(_ dayKey: String) -> String? {
        guard let d = dayKeyFormatter.date(from: dayKey),
              let next = gregorian.date(byAdding: .day, value: 1, to: d) else { return nil }
        return dayKeyFormatter.string(from: next)
    }

    /// The calendar month a day key belongs to, as "yyyy-MM". Taken off the key
    /// rather than re-derived from a date: the key's shape is fixed by the formatter
    /// above, and a second parse could only disagree with it.
    static func monthKey(ofDay dayKey: String) -> String {
        String(dayKey.prefix(7))
    }
}
