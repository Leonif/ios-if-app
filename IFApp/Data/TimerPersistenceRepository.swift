//
//  TimerPersistenceRepository.swift
//  IFApp
//
//  Stateless, non-reactive UserDefaults access for the timer substate.
//  Keys match the previous @AppStorage keys so existing installs migrate seamlessly.
//

import Foundation

protocol TimerPersistenceRepositoryProtocol {
    func load() -> (fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int)
    func save(fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int)
}

struct TimerPersistenceRepository: TimerPersistenceRepositoryProtocol {
    private enum Key {
        static let startTimestamp = "start_timestamp"
        static let isRunning = "is_running"
        static let completedSessions = "completed_sessions_count"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int) {
        (
            fastStartTimestamp: defaults.double(forKey: Key.startTimestamp),
            isRunning: defaults.bool(forKey: Key.isRunning),
            completedSessions: defaults.integer(forKey: Key.completedSessions)
        )
    }

    func save(fastStartTimestamp: Double, isRunning: Bool, completedSessions: Int) {
        defaults.set(fastStartTimestamp, forKey: Key.startTimestamp)
        defaults.set(isRunning, forKey: Key.isRunning)
        defaults.set(completedSessions, forKey: Key.completedSessions)
    }
}
