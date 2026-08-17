//
//  EndFastMath.swift
//  IFApp
//
//  Pure derivations for the end-of-fast sheet: which preset moments it offers, and
//  how the chosen one reads. "now" is injected so all of it is testable and none of
//  it reads the clock from a view.
//

import Foundation

/// What a preset chip means, independently of when it is tapped. The row hands this
/// back rather than an absolute moment: the sheet is drawn from a `TimelineView` that
/// redraws every second, so a moment resolved at draw time is the moment of a *frame*,
/// not of the tap. The offset is stable, and `EndFastMath.resolve` turns it into an
/// instant once, inside the thunk.
enum EndFastChipOffset: Equatable {
    /// Minutes back from now — the ordinary presets.
    case minutesAgo(Int)
    /// Whole days back from the standing choice, keeping its clock time — the
    /// overtime presets.
    case daysBack(Int)
}

/// One preset the sheet offers: what it selects and the label that names it. The
/// pair travels together because the label is a statement *about* that offset —
/// built separately they drift, which is how a chip comes to say "1 h ago" and set
/// something else.
struct EndFastChip: Equatable {
    let offset: EndFastChipOffset
    let label: String
}

enum EndFastMath {
    /// Minutes-ago offsets of the ordinary presets. `Just now` is an offset of zero
    /// rather than a special case, so the three are one list and the row cannot end
    /// up with a chip that has no moment behind it.
    private static let quickOffsetsMinutes = [0, 30, 60]

    /// The three presets for a given state.
    ///
    /// Two shapes, and which one applies is the state's business, not the row's:
    /// minutes-ago while the ending is recent, whole past days once the timer has run
    /// a day or more past the goal. A row of "30 min ago" in front of someone
    /// correcting a fast they forgot for two days offers them nothing they can use.
    static func chips(stage: EndFastStage, now: Double, selected: Double) -> [EndFastChip] {
        switch stage {
        case .overtime:
            // Same clock time as the standing choice — which starts on the goal end —
            // on each of the three days before today. The hour is the one the app can
            // actually justify: the moment already under consideration. It does not
            // invent a dinner time it has no way of knowing.
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

    /// The instant a chip stands for. The one definition of it: the row calls this to
    /// build its labels, the thunk calls it to set the value, and so a chip cannot say
    /// one moment and select another.
    static func resolve(_ offset: EndFastChipOffset, now: Double, selected: Double) -> Double {
        switch offset {
        case let .minutesAgo(minutes):
            return now - Double(minutes) * 60
        case let .daysBack(days):
            return shiftedByDays(selected, days: -days, relativeTo: now)
        }
    }

    /// The selected moment shifted onto the day `days` away from today, keeping its
    /// clock time. Calendar arithmetic rather than ±86400: an hour of it disappears
    /// twice a year, and a preset that lands an hour off on those two days is worse
    /// than one that is not offered.
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

    /// "Yesterday 9:10 AM" / "Mon 9:10 AM" — the day named, then the clock. The clock
    /// is isolated where it enters the string, for the reason `MealMath.fromLabel`
    /// spells out: by the time it is in the middle of a line it is a token like any
    /// other substitution.
    static func dayAndClock(_ timestamp: Double, now: Double) -> String {
        let time = BidiText.isolate(clock(timestamp))
        switch daysBefore(timestamp, now: now) {
        case 0: return time
        case 1: return strings.Meal.yesterdayAt(time)
        default: return "\(weekday(timestamp)) \(time)"
        }
    }

    /// The caption under the exact-time value: which day the value is on, and — when
    /// the sheet opened on it — that this is where the goal ran out.
    static func dayCaption(_ timestamp: Double, now: Double, isGoalEnd: Bool) -> String {
        let day: String
        switch daysBefore(timestamp, now: now) {
        case 0: day = strings.Meal.today
        case 1: day = strings.Meal.yesterday
        case let n: day = strings.Meal.daysAgo(n)
        }
        return isGoalEnd ? strings.EndFast.goalEndCaption(day) : day
    }

    /// Whether a fast this far from its goal is inside the near-goal guard.
    ///
    /// Whole minutes, rounded up: 15:00 left is 15 minutes and inside the guard, 15:01
    /// is 16 and outside it. Rounding down would put a fast 15:59 short of its goal
    /// inside a guard that says "15 minutes left".
    ///
    /// One rule in one place because two surfaces ask it: the sheet, deciding whether
    /// to warn before the end, and the result footer, deciding which consequence
    /// sentence is true afterwards. The inputs are deliberately not the same moment —
    /// the sheet asks about the fast as it stands when it opens, the footer about the
    /// fast that was actually recorded, so someone who back-dated the end further sees
    /// the warning and then the ordinary line. That is the footer describing what was
    /// saved. What must not drift is the threshold itself: two copies of "how close is
    /// close" would eventually disagree, and the disagreement would be silence, since
    /// the footer's near-goal sentence is the only place the lost day is ever named.
    static func isNearGoal(secondsLeft: Double) -> Bool {
        secondsLeft > 0 && Int(ceil(secondsLeft / 60)) <= EndFastState.nearGoalThresholdMinutes
    }

    /// Whole calendar days between the day of `timestamp` and today.
    static func daysBefore(_ timestamp: Double, now: Double) -> Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: Date(timeIntervalSince1970: timestamp))
        let to = cal.startOfDay(for: Date(timeIntervalSince1970: now))
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    /// "9:10 AM" — the region's 12/24h convention, Latin digits, as everywhere else
    /// the app draws a clock.
    static func clock(_ timestamp: Double) -> String {
        let f = DateFormatter()
        f.locale = .latinDigits
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: Date(timeIntervalSince1970: timestamp))
    }

    /// "Mon" — short weekday in the current language.
    static func weekday(_ timestamp: Double) -> String {
        let f = DateFormatter()
        f.locale = .latinDigits
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: Date(timeIntervalSince1970: timestamp))
    }

    /// "9:10 AM · 16h 00m" — the preview line's value: the moment the fast would end,
    /// and the length it would be recorded with.
    static func previewValue(end: Double, start: Double) -> String {
        let total = max(0, Int(end - start))
        return "\(BidiText.isolate(clock(end))) · \(strings.Duration.hm(total / 3600, (total / 60) % 60))"
    }

    /// "Mon 9:00 AM‑1:10 AM" — the saved fast a refusal names. Both ends, because
    /// one of them is what the person has to move away from and they cannot know
    /// which without seeing the span.
    ///
    /// The span never breaks across lines. An ASCII hyphen with ordinary spaces on
    /// both sides gave the layout two break points *inside a single value*: the line
    /// ended on "(Yesterday 9:00 -" and the next one opened with "1:10)", so the one
    /// line that exists to name the conflicting fast read as two unrelated times.
    /// Found independently by the Korean and Japanese passes.
    static func recordSpan(_ record: FastRecord, now: Double) -> String {
        let from = dayAndClock(record.startTimestamp, now: now)
        let to = BidiText.isolate(clock(record.endTimestamp))
        return "\(from)\(spanSeparator)\(to)"
    }

    /// Non-breaking spaces around the separator everywhere, and no separator spaces
    /// at all in Japanese: the range there is written with the full-width wave dash
    /// (12:00〜21:45), which carries its own side bearings and looks padded with
    /// spaces around it.
    private static var spanSeparator: String {
        Locale.current.language.languageCode?.identifier == "ja" ? "\u{301C}" : "\u{00A0}-\u{00A0}"
    }
}
