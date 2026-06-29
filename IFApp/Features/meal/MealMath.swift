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
        f.locale = .current
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    /// "Fasting since" label: "Now" when fresh, else a day-prefixed clock time.
    static func fromLabel(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> String {
        guard ateMin >= 0, minutesAgo(ateDay: ateDay, ateMin: ateMin, nowMinuteOfDay: nowMinuteOfDay) > 0 else {
            return strings.Meal.now
        }
        let time = timeLabel(ateMin: ateMin)
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
