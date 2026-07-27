//
//  MealMath.swift
//  IFApp
//
//  Pure derivations for the last-meal flow. "now" is injected so these are testable.
//

import Foundation

enum MealMath {
    /// The hard back-date limit, mirrored from the ribbon's domain.
    static var maxMinutesAgo: Int { MealScale.maxMinutes }

    /// Minutes between the logged meal time and now. 0 when fresh/now.
    ///
    /// **Clamped here on purpose, and only here.** A meal in the future is not a
    /// state this app can hold: it would back-date the fast *forward*, and the timer
    /// would count from a start that hasn't happened while the preview cheerfully
    /// said "Now". Both places that turn a meal time into a fast start
    /// (`ConfirmLastMealThunk`, `ContinueFastingThunk`) read it through this
    /// function, so neither can express it.
    static func minutesAgo(ateDay: Int, ateMin: Int, nowMinuteOfDay: Int) -> Int {
        guard ateMin >= 0 else { return 0 }
        let raw = nowMinuteOfDay - ateMin + ateDay * 1440
        return min(maxMinutesAgo, max(0, raw))
    }

    /// The inverse: (ateDay, ateMin) for a distance back from now, clamped to the
    /// same domain — so nothing upstream can hand the model a moment it can't hold.
    static func moment(minutesAgo: Int, nowMinuteOfDay: Int) -> (ateDay: Int, ateMin: Int) {
        let m = min(maxMinutesAgo, max(0, minutesAgo))
        let total = nowMinuteOfDay - m
        // Floor division: `total` goes negative as soon as the meal is before today's
        // midnight, and truncating division would round that the wrong way.
        let day = total >= 0 ? 0 : ((-total) + 1439) / 1440
        return (day, total + day * 1440)
    }

    /// Minutes ago of a concrete past moment — seeds the picker from a timestamp
    /// (the eating-window close) or from the system date picker.
    static func minutesAgo(of date: Date, now: Date = Date()) -> Int {
        let seconds = now.timeIntervalSince1970 - date.timeIntervalSince1970
        return min(maxMinutesAgo, max(0, Int((seconds / 60).rounded())))
    }

    /// Date label: 0 → Today, 1 → Yesterday, n → "n days ago".
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

    // MARK: Picker readout

    /// The picker's headline: how long ago, as one whole localized template per
    /// shape. Never assembled from a duration plus a separate "ago" — that word sits
    /// in front in de/es/fr/ar and behind in uk/pl/ja/ko, and only a full template
    /// per form survives both.
    /// The shape stays fixed inside a band, including when a component lands on zero
    /// ("23h 00m ago", "1d 0h ago"). Dropping the zero shortens the line by four or
    /// five characters, and since the headline is centred, every other snap step made
    /// it jump sideways — with the scale set to 30-minute steps that reads as flicker,
    /// not as a value settling. A shape change now happens only at a band edge, where
    /// the unit itself genuinely changes.
    static func agoLabel(minutesAgo mins: Int) -> String {
        guard mins > 0 else { return strings.Meal.justNow }
        if mins < 60 { return strings.Meal.agoMinutes(mins) }
        if mins < 1440 { return strings.Meal.agoRelative(mins / 60, mins % 60) }
        return strings.Meal.agoDays(mins / 1440, (mins % 1440) / 60)
    }

    /// The quieter line under the headline: the same moment on the clock. This is
    /// where the calendar lives now — there is no date control any more, the day
    /// follows from the chosen moment and changes on its own.
    static func absoluteLabel(ateDay: Int, ateMin: Int) -> String {
        let time = timeLabel(ateMin: ateMin)
        switch ateDay {
        case 0: return strings.Meal.todayAt(time)
        case 1: return strings.Meal.yesterdayAt(time)
        default: return strings.Meal.dateAt(dayLabel(daysAgo: ateDay), time)
        }
    }

    /// "Sat 18 Jul" — the far end of the readout's second line.
    static func dayLabel(daysAgo: Int) -> String {
        formattedDay(daysAgo: daysAgo, template: "EEE d MMM")
    }

    /// The short day name the ribbon prints beside a midnight rule: "Yesterday" for
    /// the first one back, weekday abbreviations for the rest.
    static func shortDayLabel(daysAgo: Int) -> String {
        daysAgo == 1 ? strings.Meal.yesterday : formattedDay(daysAgo: daysAgo, template: "EEE")
    }

    private static func formattedDay(daysAgo: Int, template: String) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let f = DateFormatter()
        f.locale = .latinDigits
        f.setLocalizedDateFormatFromTemplate(template)
        return f.string(from: date)
    }
}
