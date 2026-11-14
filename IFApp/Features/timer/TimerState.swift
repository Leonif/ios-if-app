//
//  TimerState.swift
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

enum StreakDisplay: Equatable, Sendable {
    case alive(Int)
    case justEnded(Int, lastGoalDate: String)
    case none

    var count: Int {
        switch self {
        case .alive(let days), .justEnded(let days, _): return days
        case .none: return 0
        }
    }

    var hasEnded: Bool {
        if case .justEnded = self { return true }
        return false
    }

    var lastGoalDate: String? {
        if case .justEnded(_, let dayKey) = self { return dayKey }
        return nil
    }
}

struct TimerState: Equatable, Sendable {
    var fastStartTimestamp: Double = 0
    var goalHours: Double = 0
    var isRunning: Bool = false
    var stagedElapsed: TimeInterval = 0
    var fastEndTimestamp: Double = 0
    var completedSessionsCount: Int = 0
    var hasCelebrated: Bool = false
    var eatingStartTimestamp: Double = 0
    var isEating: Bool = false
    var streakCount: Int = 0
    var lastGoalDate: String? = nil
    var freezeSpentMonth: String? = nil

    func streak(ownsFreeze: Bool) -> StreakStatus {
        StreakStatus(count: streakCount,
                     lastGoalDate: lastGoalDate,
                     freezeSpentMonth: freezeSpentMonth,
                     ownsFreeze: ownsFreeze)
    }

    func resolvedGoalHours(planHours: Double) -> Double {
        goalHours > 0 ? goalHours : planHours
    }

    func startTimestamp(at now: Double) -> Double {
        now - stagedElapsed
    }

    func eatingEndTimestamp(plan: Plan) -> Double {
        Self.windowEndTimestamp(openedAt: eatingStartTimestamp, plan: plan)
    }

    static func windowEndTimestamp(openedAt: Double, plan: Plan) -> Double {
        openedAt + Double(plan.windowHours) * 3600
    }

    static let closedWindowHorizon: TimeInterval = 24 * 3600

    static func closedWindowHasLapsed(closedAt: Double, now: Double) -> Bool {
        now - closedAt >= closedWindowHorizon
    }

    func droppingLapsedEnding(at now: Double, plan: Plan) -> TimerState {
        guard !isRunning, !isEating, stagedElapsed > 0 else { return self }
        if fastEndTimestamp > 0 {
            let windowEnd = Self.windowEndTimestamp(openedAt: fastEndTimestamp, plan: plan)
            guard Self.closedWindowHasLapsed(closedAt: windowEnd, now: now) else { return self }
        }
        return withoutCycle()
    }

    func withoutCycle() -> TimerState {
        var idle = self
        idle.isRunning = false
        idle.fastStartTimestamp = 0
        idle.goalHours = 0
        idle.stagedElapsed = 0
        idle.fastEndTimestamp = 0
        idle.hasCelebrated = false
        idle.isEating = false
        idle.eatingStartTimestamp = 0
        return idle
    }
}
