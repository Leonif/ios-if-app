//
//  StreakStatus.swift
//  IFApp
//

import Foundation

struct StreakStatus: Equatable, Sendable {
    var count: Int = 0
    var lastGoalDate: String? = nil
    var freezeSpentMonth: String? = nil
    var ownsFreeze: Bool = false

    func freezeCovers(_ dayKey: String) -> Bool {
        guard ownsFreeze,
              let lastGoalDate,
              Clock.daysBetween(lastGoalDate, dayKey) == 2,
              let month = Self.freezeMonthCharged(afterGoalOn: lastGoalDate) else { return false }
        return freezeSpentMonth != month
    }

    static func freezeMonthCharged(afterGoalOn lastGoalDate: String) -> String? {
        Clock.nextDay(lastGoalDate).map(Clock.monthKey(ofDay:))
    }

    func freezeMonth(coveringGapTo dayKey: String) -> String? {
        guard freezeCovers(dayKey), let lastGoalDate else { return nil }
        return Self.freezeMonthCharged(afterGoalOn: lastGoalDate)
    }

    func displayed(at now: Date) -> Int {
        guard let lastGoalDate else { return 0 }
        let today = Clock.dayKey(now)
        if lastGoalDate == today || Clock.isDayBefore(lastGoalDate, today) { return count }
        return freezeCovers(today) ? count : 0
    }

    static let lostRunFreshnessDays = 7

    func display(at now: Date) -> StreakDisplay {
        let shown = displayed(at: now)
        if shown > 0 { return .alive(shown) }
        guard count > 0, let lastGoalDate,
              let gap = Clock.daysBetween(lastGoalDate, Clock.dayKey(now)),
              gap <= Self.lostRunFreshnessDays else { return .none }
        return .justEnded(count, lastGoalDate: lastGoalDate)
    }
}
