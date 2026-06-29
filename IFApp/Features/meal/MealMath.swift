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
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(ateDay) days ago"
        }
    }

    /// 12-hour clock label for a minute-of-day, e.g. "7:00 PM".
    static func timeLabel(ateMin: Int) -> String {
        let minute = ateMin < 0 ? 0 : ateMin
        let h24 = minute / 60
        let m = minute % 60
        let period = h24 < 12 ? "AM" : "PM"
        var h12 = h24 % 12
        if h12 == 0 { h12 = 12 }
        return String(format: "%d:%02d %@", h12, m, period)
    }

    /// "Fasting since" label: "Now" when fresh, else a day-prefixed clock time.
    static func fromLabel(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> String {
        guard ateMin >= 0, minutesAgo(ateDay: ateDay, ateMin: ateMin, nowMinuteOfDay: nowMinuteOfDay) > 0 else {
            return "Now"
        }
        let time = timeLabel(ateMin: ateMin)
        switch ateDay {
        case 0: return time
        case 1: return "Yesterday \(time)"
        default: return "\(ateDay) days ago \(time)"
        }
    }

    /// Short "Xh Ym in" note (or "starting fresh").
    static func note(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> String {
        let mins = minutesAgo(ateDay: ateDay, ateMin: ateMin, nowMinuteOfDay: nowMinuteOfDay)
        guard mins > 0 else { return "starting fresh" }
        return String(format: "%dh %02dm in", mins / 60, mins % 60)
    }
}
