//
//  TimerPersistenceRepository.swift
//  IFApp
//

import Foundation

struct TimerPersistenceRepository: TimerPersistenceRepositoryProtocol {
    private enum Key {
        static let startTimestamp = "start_timestamp"
        static let goalHours = "goal_hours"
        static let isRunning = "is_running"
        static let completedSessions = "completed_sessions_count"
        static let hasCelebrated = "has_celebrated"
        static let eatingStartTimestamp = "eating_start_timestamp"
        static let isEating = "is_eating"
        static let stagedElapsed = "staged_elapsed"
        static let fastEndTimestamp = "fast_end_timestamp"
        static let planHours = "plan_hours"
        static let legacyPlanIdx = "plan_idx"
        static let streakCount = "streak_count"
        static let streakLastGoalDate = "streak_last_goal_date"
        static let streakFreezeSpentMonth = "streak_freeze_spent_month"
        static let streakLastMilestoneShown = "streak_last_milestone_shown"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, stagedElapsed: Double, fastEndTimestamp: Double, streakCount: Int, lastGoalDate: String?, freezeSpentMonth: String?) {
        (
            fastStartTimestamp: defaults.double(forKey: Key.startTimestamp),
            goalHours: defaults.double(forKey: Key.goalHours),
            isRunning: defaults.bool(forKey: Key.isRunning),
            completedSessions: defaults.integer(forKey: Key.completedSessions),
            hasCelebrated: defaults.bool(forKey: Key.hasCelebrated),
            eatingStartTimestamp: defaults.double(forKey: Key.eatingStartTimestamp),
            isEating: defaults.bool(forKey: Key.isEating),
            stagedElapsed: defaults.double(forKey: Key.stagedElapsed),
            fastEndTimestamp: defaults.double(forKey: Key.fastEndTimestamp),
            streakCount: defaults.integer(forKey: Key.streakCount),
            lastGoalDate: defaults.string(forKey: Key.streakLastGoalDate),
            freezeSpentMonth: defaults.string(forKey: Key.streakFreezeSpentMonth)
        )
    }

    func save(fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, stagedElapsed: Double, fastEndTimestamp: Double, streakCount: Int, lastGoalDate: String?, freezeSpentMonth: String?) {
        defaults.set(fastStartTimestamp, forKey: Key.startTimestamp)
        defaults.set(goalHours, forKey: Key.goalHours)
        defaults.set(isRunning, forKey: Key.isRunning)
        defaults.set(completedSessions, forKey: Key.completedSessions)
        defaults.set(hasCelebrated, forKey: Key.hasCelebrated)
        defaults.set(eatingStartTimestamp, forKey: Key.eatingStartTimestamp)
        defaults.set(isEating, forKey: Key.isEating)
        defaults.set(stagedElapsed, forKey: Key.stagedElapsed)
        defaults.set(fastEndTimestamp, forKey: Key.fastEndTimestamp)
        defaults.set(streakCount, forKey: Key.streakCount)
        if let lastGoalDate {
            defaults.set(lastGoalDate, forKey: Key.streakLastGoalDate)
        } else {
            defaults.removeObject(forKey: Key.streakLastGoalDate)
        }
        if let freezeSpentMonth {
            defaults.set(freezeSpentMonth, forKey: Key.streakFreezeSpentMonth)
        } else {
            defaults.removeObject(forKey: Key.streakFreezeSpentMonth)
        }
    }

    func loadPlanHours() -> Int? {
        if let hours = defaults.object(forKey: Key.planHours) as? Int { return hours }

        let legacy = defaults.object(forKey: Key.legacyPlanIdx) as? Int
        defaults.removeObject(forKey: Key.legacyPlanIdx)

        guard let idx = legacy, Plan.presets.indices.contains(idx) else { return nil }
        let hours = Plan.presets[idx].hours
        defaults.set(hours, forKey: Key.planHours)
        return hours
    }

    func savePlanHours(_ hours: Int) {
        defaults.set(hours, forKey: Key.planHours)
    }

    func loadLastMilestoneShown() -> Int {
        defaults.integer(forKey: Key.streakLastMilestoneShown)
    }

    func saveLastMilestoneShown(_ days: Int) {
        defaults.set(days, forKey: Key.streakLastMilestoneShown)
    }
}
