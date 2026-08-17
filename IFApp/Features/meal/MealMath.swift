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

    /// The domain clamp, and the only one. A meal in the future is not a state this
    /// app can hold: it would back-date the fast *forward*, and the timer would count
    /// from a start that hasn't happened while the readout cheerfully said "Just now".
    /// A meal further back than the ribbon reaches is not one either. Every way a
    /// distance enters the model — ribbon, chip, exact time, the window-close seed —
    /// arrives through `MealState.set`, which arrives here, so none of them can
    /// express either.
    static func clamped(_ minutes: Int) -> Int {
        min(maxMinutesAgo, max(0, minutes))
    }

    /// The fast start a logged meal implies, as an epoch timestamp.
    ///
    /// One definition for both callers on purpose. `ConfirmLastMealThunk` and
    /// `ContinueFastingThunk` answer the same question from different screens, and
    /// while the arithmetic was written out twice the two copies drifted: only one of
    /// them carried the floor that keeps a fast from starting after the moment it is
    /// started. The floor is `clamped` above — a non-negative distance cannot produce
    /// a start in the future — so there is nothing left for a caller to remember.
    static func fastStart(minutesAgo: Int, now: Double) -> Double {
        now - Double(clamped(minutesAgo)) * 60
    }

    /// (ateDay, ateMin) for a distance back from now — the derivation that turns the
    /// stored distance into something displayable. Clamped to the same domain, so
    /// nothing upstream can hand the labels a moment the model can't hold.
    static func moment(minutesAgo: Int, nowMinuteOfDay: Int) -> (ateDay: Int, ateMin: Int) {
        let m = clamped(minutesAgo)
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
        return clamped(Int((seconds / 60).rounded()))
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
    ///
    /// The clock time is isolated, all three branches of it. Not only the two that
    /// visibly sit inside a sentence here: the bare one is no less a substitution,
    /// because every caller composes this value further — into "… · 2h 40m in" for
    /// the picker preview, into `fastCountsFrom` for the subline — and by then the
    /// clock is a token in the middle of a line like the other two. Isolating at the
    /// point the clock enters the string, rather than at each place it ends up, is
    /// what keeps that true for the next caller as well.
    static func fromLabel(minutesAgo: Int, nowMinuteOfDay: Int) -> String {
        guard clamped(minutesAgo) > 0 else { return strings.Meal.now }
        let moment = moment(minutesAgo: minutesAgo, nowMinuteOfDay: nowMinuteOfDay)
        let time = BidiText.isolate(timeLabel(ateMin: moment.ateMin))
        switch moment.ateDay {
        case 0: return time
        case 1: return strings.Meal.yesterdayAt(time)
        default: return "\(dateLabel(ateDay: moment.ateDay)) \(time)"
        }
    }

    /// Short "Xh Ym in" note (or "starting fresh").
    static func note(minutesAgo: Int) -> String {
        let mins = clamped(minutesAgo)
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
    @MainActor static func absoluteLabel(ateDay: Int, ateMin: Int) -> String {
        let time = timeLabel(ateMin: ateMin)
        switch ateDay {
        case 0: return strings.Meal.todayAt(time)
        case 1: return strings.Meal.yesterdayAt(time)
        default: return strings.Meal.dateAt(dayLabel(daysAgo: ateDay), time)
        }
    }

    /// "Sat 18 Jul" — the far end of the readout's second line.
    @MainActor static func dayLabel(daysAgo: Int) -> String {
        formattedDay(daysAgo: daysAgo, template: "EEE d MMM")
    }

    /// The short day name the ribbon prints beside a midnight rule: "Yesterday" for
    /// the first one back, weekday abbreviations for the rest.
    @MainActor static func shortDayLabel(daysAgo: Int) -> String {
        daysAgo == 1 ? strings.Meal.yesterday : formattedDay(daysAgo: daysAgo, template: "EEE")
    }

    @MainActor private static func formattedDay(daysAgo: Int, template: String) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return dayFormatter(template).string(from: date)
    }

    /// Day formatters are cached because `shortDayLabel` is called from inside the
    /// ribbon's `Canvas` draw — once per midnight rule on screen, on every frame of a
    /// drag. Building a `DateFormatter` is one of the more expensive things in
    /// Foundation, and seven of them per frame is a stutter on the one gesture this
    /// screen exists for.
    ///
    /// Keyed by locale as well as by template, so it survives a language change
    /// rather than serving the previous language's day names for the rest of the
    /// process. Main-thread only: both callers draw.
    @MainActor private static var dayFormatters: [String: DateFormatter] = [:]

    @MainActor private static func dayFormatter(_ template: String) -> DateFormatter {
        let locale = Locale.latinDigits
        let key = "\(locale.identifier)|\(template)"
        if let cached = dayFormatters[key] { return cached }
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate(template)
        dayFormatters[key] = f
        return f
    }
}
