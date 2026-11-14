//
//  MealMath.swift
//  IFApp
//

import Foundation

enum MealMath {
    static var maxMinutesAgo: Int { MealScale.maxMinutes }

    static func clamped(_ minutes: Int) -> Int {
        min(maxMinutesAgo, max(0, minutes))
    }

    static func fastStart(minutesAgo: Int, now: Double) -> Double {
        now - Double(clamped(minutesAgo)) * 60
    }

    static func moment(minutesAgo: Int, nowMinuteOfDay: Int) -> (ateDay: Int, ateMin: Int) {
        let m = clamped(minutesAgo)
        let total = nowMinuteOfDay - m
        let day = total >= 0 ? 0 : ((-total) + 1439) / 1440
        return (day, total + day * 1440)
    }

    static func minutesAgo(of date: Date, now: Date = Date()) -> Int {
        let seconds = now.timeIntervalSince1970 - date.timeIntervalSince1970
        return clamped(Int((seconds / 60).rounded()))
    }

    static func dateLabel(ateDay: Int) -> String {
        switch ateDay {
        case 0: return strings.Meal.today
        case 1: return strings.Meal.yesterday
        default: return strings.Meal.daysAgo(ateDay)
        }
    }

    static func timeLabel(ateMin: Int) -> String {
        let minute = ateMin < 0 ? 0 : ateMin
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .minute, value: minute, to: base) ?? base
        let f = DateFormatter()
        f.locale = .latinDigits
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

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

    static func note(minutesAgo: Int) -> String {
        let mins = clamped(minutesAgo)
        guard mins > 0 else { return strings.Meal.startingFresh }
        return strings.Meal.noteIn(mins / 60, mins % 60)
    }

    // MARK: - Picker readout

    static func agoLabel(minutesAgo mins: Int) -> String {
        guard mins > 0 else { return strings.Meal.justNow }
        if mins < 60 { return strings.Meal.agoMinutes(mins) }
        if mins < 1440 { return strings.Meal.agoRelative(mins / 60, mins % 60) }
        return strings.Meal.agoDays(mins / 1440, (mins % 1440) / 60)
    }

    @MainActor static func absoluteLabel(ateDay: Int, ateMin: Int) -> String {
        let time = timeLabel(ateMin: ateMin)
        switch ateDay {
        case 0: return strings.Meal.todayAt(time)
        case 1: return strings.Meal.yesterdayAt(time)
        default: return strings.Meal.dateAt(dayLabel(daysAgo: ateDay), time)
        }
    }

    @MainActor static func dayLabel(daysAgo: Int) -> String {
        formattedDay(daysAgo: daysAgo, template: "EEE d MMM")
    }

    @MainActor static func shortDayLabel(daysAgo: Int) -> String {
        daysAgo == 1 ? strings.Meal.yesterday : formattedDay(daysAgo: daysAgo, template: "EEE")
    }

    @MainActor private static func formattedDay(daysAgo: Int, template: String) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return dayFormatter(template).string(from: date)
    }

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
