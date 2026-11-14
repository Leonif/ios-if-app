//
//  EndFastMath.swift
//  IFApp
//

import Foundation

enum EndFastMath {
    private static let quickOffsetsMinutes = [0, 30, 60]

    static func chips(stage: EndFastStage, now: Double, selected: Double) -> [EndFastChip] {
        switch stage {
        case .overtime:
            return (1...3).map { daysBack in
                let offset = EndFastChipOffset.daysBack(daysBack)
                return EndFastChip(offset: offset,
                                   label: dayAndClock(resolve(offset, now: now, selected: selected),
                                                      now: now))
            }
        case .picker, .nearGoal, .refusal:
            return quickOffsetsMinutes.map { minutes in
                EndFastChip(offset: .minutesAgo(minutes), label: minutesAgoLabel(minutes))
            }
        }
    }

    static func resolve(_ offset: EndFastChipOffset, now: Double, selected: Double) -> Double {
        switch offset {
        case let .minutesAgo(minutes):
            return now - Double(minutes) * 60
        case let .daysBack(days):
            return shiftedByDays(selected, days: -days, relativeTo: now)
        }
    }

    private static func shiftedByDays(_ timestamp: Double, days: Int, relativeTo now: Double) -> Double {
        let cal = Calendar.current
        let source = Date(timeIntervalSince1970: timestamp)
        let today = cal.startOfDay(for: Date(timeIntervalSince1970: now))
        let target = cal.date(byAdding: .day, value: days, to: today) ?? today
        let time = cal.dateComponents([.hour, .minute], from: source)
        return (cal.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: target)
                ?? target).timeIntervalSince1970
    }

    private static func minutesAgoLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: return strings.Meal.justNow
        case 60: return strings.EndFast.chip1Hour
        default: return strings.EndFast.chipMinutesAgo(minutes)
        }
    }

    static func dayAndClock(_ timestamp: Double, now: Double) -> String {
        let time = BidiText.isolate(clock(timestamp))
        switch daysBefore(timestamp, now: now) {
        case 0: return time
        case 1: return strings.Meal.yesterdayAt(time)
        default: return "\(weekday(timestamp)) \(time)"
        }
    }

    static func dayCaption(_ timestamp: Double, now: Double, isGoalEnd: Bool) -> String {
        let day: String
        switch daysBefore(timestamp, now: now) {
        case 0: day = strings.Meal.today
        case 1: day = strings.Meal.yesterday
        case let n: day = strings.Meal.daysAgo(n)
        }
        return isGoalEnd ? strings.EndFast.goalEndCaption(day) : day
    }

    static func isNearGoal(secondsLeft: Double) -> Bool {
        secondsLeft > 0 && Int(ceil(secondsLeft / 60)) <= EndFastState.nearGoalThresholdMinutes
    }

    static func daysBefore(_ timestamp: Double, now: Double) -> Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: Date(timeIntervalSince1970: timestamp))
        let to = cal.startOfDay(for: Date(timeIntervalSince1970: now))
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    static func clock(_ timestamp: Double) -> String {
        let f = DateFormatter()
        f.locale = .latinDigits
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: Date(timeIntervalSince1970: timestamp))
    }

    static func weekday(_ timestamp: Double) -> String {
        let f = DateFormatter()
        f.locale = .latinDigits
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: Date(timeIntervalSince1970: timestamp))
    }

    static func previewValue(end: Double, start: Double) -> String {
        let total = max(0, Int(end - start))
        return "\(BidiText.isolate(clock(end))) · \(strings.Duration.hm(total / 3600, (total / 60) % 60))"
    }

    static func recordSpan(_ record: FastRecord, now: Double) -> String {
        let from = dayAndClock(record.startTimestamp, now: now)
        let to = BidiText.isolate(clock(record.endTimestamp))
        return "\(from)\(spanSeparator)\(to)"
    }

    private static var spanSeparator: String {
        Locale.current.language.languageCode?.identifier == "ja" ? "\u{301C}" : "\u{00A0}-\u{00A0}"
    }
}
