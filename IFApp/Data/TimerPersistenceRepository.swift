//
//  TimerPersistenceRepository.swift
//  IFApp
//
//  Stateless, non-reactive UserDefaults access for the timer substate.
//  Keys match the previous @AppStorage keys so existing installs migrate seamlessly.
//

import Foundation

protocol TimerPersistenceRepositoryProtocol {
    func load() -> (fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool)
    func save(fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool)
    func loadPlanIdx() -> Int?
    func savePlanIdx(_ idx: Int)
}

struct TimerPersistenceRepository: TimerPersistenceRepositoryProtocol {
    private enum Key {
        static let startTimestamp = "start_timestamp"
        static let isRunning = "is_running"
        static let completedSessions = "completed_sessions_count"
        static let hasCelebrated = "has_celebrated"
        static let eatingStartTimestamp = "eating_start_timestamp"
        static let isEating = "is_eating"
        static let planIdx = "plan_idx"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool) {
        (
            fastStartTimestamp: defaults.double(forKey: Key.startTimestamp),
            isRunning: defaults.bool(forKey: Key.isRunning),
            completedSessions: defaults.integer(forKey: Key.completedSessions),
            hasCelebrated: defaults.bool(forKey: Key.hasCelebrated),
            eatingStartTimestamp: defaults.double(forKey: Key.eatingStartTimestamp),
            isEating: defaults.bool(forKey: Key.isEating)
        )
    }

    func save(fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool) {
        defaults.set(fastStartTimestamp, forKey: Key.startTimestamp)
        defaults.set(isRunning, forKey: Key.isRunning)
        defaults.set(completedSessions, forKey: Key.completedSessions)
        defaults.set(hasCelebrated, forKey: Key.hasCelebrated)
        defaults.set(eatingStartTimestamp, forKey: Key.eatingStartTimestamp)
        defaults.set(isEating, forKey: Key.isEating)
    }

    func loadPlanIdx() -> Int? {
        defaults.object(forKey: Key.planIdx) as? Int
    }

    func savePlanIdx(_ idx: Int) {
        defaults.set(idx, forKey: Key.planIdx)
    }
}
