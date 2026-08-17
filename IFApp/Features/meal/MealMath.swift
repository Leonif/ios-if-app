//
//  MealMath.swift
//  IFApp
//
//  Pure derivations for the last-meal flow. "now" is injected so these are testable.
//

import Foundation

enum MealMath {
    /// Minutes between the logged meal time and now. 0 when fresh/now.
    static func minutesAgo(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> Int {
        guard ateMin >= 0 else { return 0 }
        return nowMinuteOfDay - ateMin + ateDay * 1440
    }

    /// (ateDay, ateMin) of a past moment relative to `now` — seeds the picker to a
    /// concrete time (the eating-window close). Days clamp to the stepper's 0...6.
    static func dayAndMinute(of date: Date, now: Date = Date()) -> (ateDay: Int, ateMin: Int) {
        let cal = Calendar.current
        let c = cal.dateComponents([.hour, .minute], from: date)
        let minute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        return (min(6, max(0, days)), minute)
    }

    /// Date stepper label: 0 → Today, 1 → Yesterday, n → "n days ago".
    static func dateLabel(ateDay: Int) -> String {
        switch ateDay {
        case 0: return strings.Meal.today
        case 1: return strings.Meal.yesterday
        default: return strings.Meal.daysAgo(ateDay)
        }
    }

    /// Locale-aware clock label for a minute-of-day: "7:00 PM" (en) / "19:00" (uk).
    static func timeLabel(ateMin: Int) -> String {
        let minute = ateMin < 0 ? 0 : ateMin
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .minute, value: minute, to: base) ?? base
        let f = DateFormatter()
        // Latin digits (and the Gregorian calendar) so this clock reads the same as
        // the manually built numerals it sits beside — see Locale.latinDigits.
        f.locale = .latinDigits
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    /// "Fasting since" label: "Now" when fresh, else a day-prefixed clock time.
    ///
    /// The clock time is isolated, all three branches of it. Not only the two that
    /// visibly sit inside a sentence here: the bare one is no less a substitution,
    /// because every caller composes this value further — into "… · 2h 40m in" for
    /// the picker preview, into `fastCountsFrom` for the subline — and by then the
    /// clock is a token in the middle of a line like the other two. Isolating at the
    /// point the clock enters the string, rather than at each place it ends up, is
    /// what keeps that true for the next caller as well.
    static func fromLabel(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> String {
        guard ateMin >= 0, minutesAgo(ateDay: ateDay, ateMin: ateMin, nowMinuteOfDay: nowMinuteOfDay) > 0 else {
            return strings.Meal.now
        }
        let time = BidiText.isolate(timeLabel(ateMin: ateMin))
        switch ateDay {
        case 0: return time
        case 1: return strings.Meal.yesterdayAt(time)
        default: return "\(dateLabel(ateDay: ateDay)) \(time)"
        }
    }

    /// Short "Xh Ym in" note (or "starting fresh").
    static func note(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> String {
        let mins = minutesAgo(ateDay: ateDay, ateMin: ateMin, nowMinuteOfDay: nowMinuteOfDay)
        guard mins > 0 else { return strings.Meal.startingFresh }
        return strings.Meal.noteIn(mins / 60, mins % 60)
    }
}
