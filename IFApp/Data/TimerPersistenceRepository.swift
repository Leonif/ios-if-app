//
//  TimerPersistenceRepository.swift
//  IFApp
//
//  Stateless, non-reactive UserDefaults access for the timer substate.
//  Keys match the previous @AppStorage keys so existing installs migrate seamlessly.
//

import Foundation

protocol TimerPersistenceRepositoryProtocol {
    func load() -> (fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, streakCount: Int, lastGoalDate: String?)
    func save(fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, streakCount: Int, lastGoalDate: String?)
    /// The selected plan's fast length in whole hours. nil = never saved.
    func loadPlanHours() -> Int?
    func savePlanHours(_ hours: Int)
    /// The highest streak milestone (3/7/14/30) whose card was already shown. 0 = none.
    func loadLastMilestoneShown() -> Int
    func saveLastMilestoneShown(_ days: Int)
}

struct TimerPersistenceRepository: TimerPersistenceRepositoryProtocol {
    private enum Key {
        static let startTimestamp = "start_timestamp"
        static let goalHours = "goal_hours"
        static let isRunning = "is_running"
        static let completedSessions = "completed_sessions_count"
        static let hasCelebrated = "has_celebrated"
        static let eatingStartTimestamp = "eating_start_timestamp"
        static let isEating = "is_eating"
        static let planHours = "plan_hours"
        /// Pre-1.5.0 plan storage: an index into the four presets. Read once for
        /// migration, never written again.
        static let legacyPlanIdx = "plan_idx"
        static let streakCount = "streak_count"
        static let streakLastGoalDate = "streak_last_goal_date"
        static let streakLastMilestoneShown = "streak_last_milestone_shown"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, streakCount: Int, lastGoalDate: String?) {
        (
            fastStartTimestamp: defaults.double(forKey: Key.startTimestamp),
            // Absent (state written before 1.5.0) reads as 0, which every reader
            // resolves to the current plan — i.e. exactly the old behaviour.
            goalHours: defaults.double(forKey: Key.goalHours),
            isRunning: defaults.bool(forKey: Key.isRunning),
            completedSessions: defaults.integer(forKey: Key.completedSessions),
            hasCelebrated: defaults.bool(forKey: Key.hasCelebrated),
            eatingStartTimestamp: defaults.double(forKey: Key.eatingStartTimestamp),
            isEating: defaults.bool(forKey: Key.isEating),
            streakCount: defaults.integer(forKey: Key.streakCount),
            lastGoalDate: defaults.string(forKey: Key.streakLastGoalDate)
        )
    }

    func save(fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, streakCount: Int, lastGoalDate: String?) {
        defaults.set(fastStartTimestamp, forKey: Key.startTimestamp)
        defaults.set(goalHours, forKey: Key.goalHours)
        defaults.set(isRunning, forKey: Key.isRunning)
        defaults.set(completedSessions, forKey: Key.completedSessions)
        defaults.set(hasCelebrated, forKey: Key.hasCelebrated)
        defaults.set(eatingStartTimestamp, forKey: Key.eatingStartTimestamp)
        defaults.set(isEating, forKey: Key.isEating)
        defaults.set(streakCount, forKey: Key.streakCount)
        if let lastGoalDate {
            defaults.set(lastGoalDate, forKey: Key.streakLastGoalDate)
        } else {
            defaults.removeObject(forKey: Key.streakLastGoalDate)
        }
    }

    /// Hours first; falling back once to the pre-1.5.0 preset index for installs that
    /// updated over a version which stored a plan as a position in a list.
    ///
    /// The fallback converts and then removes the old key instead of leaving it to be
    /// re-read every launch. Otherwise an install whose owner never opens the plan
    /// editor would keep its plan as an index forever — and an index only means
    /// something relative to the order of `Plan.presets`, so reordering that array
    /// would quietly re-interpret the saved plan on exactly those installs.
    func loadPlanHours() -> Int? {
        if let hours = defaults.object(forKey: Key.planHours) as? Int { return hours }

        let legacy = defaults.object(forKey: Key.legacyPlanIdx) as? Int
        // Read once, gone either way: an index we cannot interpret is not worth
        // keeping, and leaving it would make the migration depend on presets order
        // again the next time this runs.
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
