//
//  TimerState.swift
//  IFApp
//

import Foundation

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

    func elapsed(at now: Double) -> TimeInterval {
        isRunning ? max(0, now - fastStartTimestamp) : stagedElapsed
    }

    func eatingEndTimestamp(plan: Plan) -> Double {
        Self.windowEndTimestamp(openedAt: eatingStartTimestamp, plan: plan)
    }

    func eatingRemaining(at now: Double, plan: Plan) -> TimeInterval {
        max(0, eatingEndTimestamp(plan: plan) - now)
    }

    func eatingOverElapsed(at now: Double, plan: Plan) -> TimeInterval {
        max(0, now - eatingEndTimestamp(plan: plan))
    }

    func screenState(at now: Double, plan: Plan) -> TimerScreenState {
        if isEating {
            if eatingRemaining(at: now, plan: plan) > 0 { return .eating }
            return Self.closedWindowHasLapsed(closedAt: eatingEndTimestamp(plan: plan), now: now) ? .idle : .eatingOver
        }
        if !isRunning { return stagedElapsed > 0 ? .complete : .idle }
        let progress = PhaseProgress.compute(elapsed: elapsed(at: now), goalHours: plan.fastHours)
        return progress.isComplete ? .goalReached : .active
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
