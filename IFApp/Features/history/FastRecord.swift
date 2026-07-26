//
//  FastRecord.swift
//  IFApp
//
//  One finished fast. Only the four raw facts are stored — duration, whether the
//  goal was reached, the phase it ended in and midnight crossings are all derived
//  here. Anything cached would have to be kept in sync on deletion; derived values
//  cannot drift.
//

import Foundation

struct FastRecord: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    /// Epoch seconds the fast began (after any back-dating).
    let startTimestamp: Double
    /// Epoch seconds the fast ended.
    let endTimestamp: Double
    /// The plan's goal in hours at the time the fast ended.
    let goalHours: Double
    /// The plan's ratio label ("16:8"). Stored as text rather than an index so a
    /// future custom-plan feature can't retroactively relabel old records.
    let planLabel: String

    var duration: TimeInterval { max(0, endTimestamp - startTimestamp) }

    var goalReached: Bool { duration >= goalHours * 3600 }

    /// Fraction of the goal, clamped for the ring arc.
    var goalFraction: Double {
        let goal = max(1, goalHours * 3600)
        return min(1, duration / goal)
    }

    /// The phase the fast actually ended in — the row's ring colour.
    var reachedPhase: Phase {
        PhaseProgress.compute(elapsed: duration, goalHours: goalHours).phase
    }

    /// Fasts past a full day get the `Extended` chip and a second inner arc.
    var isExtended: Bool { duration >= 24 * 3600 }

    /// Hours past 24h as a 0...1 fraction of a second day — the inner arc.
    var extendedFraction: Double {
        guard isExtended else { return 0 }
        return min(1, (duration - 24 * 3600) / (24 * 3600))
    }

    var startDate: Date { Date(timeIntervalSince1970: startTimestamp) }
    var endDate: Date { Date(timeIntervalSince1970: endTimestamp) }

    /// The local day this fast credits to the streak — the same rule the live streak
    /// uses (`Clock.goalDayKey`). nil when the goal was never reached.
    var goalDayKey: String? {
        guard goalReached else { return nil }
        return Clock.goalDayKey(fastStart: startTimestamp, goalHours: goalHours)
    }
}
