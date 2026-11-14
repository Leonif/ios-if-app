//
//  FastRecord.swift
//  IFApp
//

import Foundation

struct FastRecord: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let startTimestamp: Double
    let endTimestamp: Double
    let goalHours: Double
    let planLabel: String

    var duration: TimeInterval { max(0, endTimestamp - startTimestamp) }

    var goalReached: Bool { duration >= goalHours * 3600 }

    var goalFraction: Double {
        let goal = max(1, goalHours * 3600)
        return min(1, duration / goal)
    }

    var reachedPhase: Phase {
        PhaseProgress.compute(elapsed: duration, goalHours: goalHours).phase
    }

    var isExtended: Bool { duration >= 24 * 3600 }

    var extendedFraction: Double {
        guard isExtended else { return 0 }
        return min(1, (duration - 24 * 3600) / (24 * 3600))
    }

    var startDate: Date { Date(timeIntervalSince1970: startTimestamp) }
    var endDate: Date { Date(timeIntervalSince1970: endTimestamp) }

    var goalDayKey: String? {
        guard goalReached else { return nil }
        return Clock.goalDayKey(fastStart: startTimestamp, goalHours: goalHours)
    }
}

extension FastRecord {
    func overlaps(start: Double, end: Double) -> Bool {
        start < endTimestamp && end > startTimestamp
    }

    static func firstOverlap(in records: [FastRecord], start: Double, end: Double) -> FastRecord? {
        records
            .sorted { $0.endTimestamp > $1.endTimestamp }
            .first { $0.overlaps(start: start, end: end) }
    }
}
