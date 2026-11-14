//
//  HistoryStats.swift
//  IFApp
//

import Foundation

struct HistoryMonthGroup: Identifiable, Equatable {
    let id: String
    let month: Date
    let records: [FastRecord]

    var totalHours: Int {
        Int(records.reduce(0) { $0 + $1.duration } / 3600)
    }
}

struct HistoryDay: Identifiable, Equatable {
    let date: Date
    let reachedGoal: Bool
    var id: String { Clock.dayKey(date) }
}

struct HistoryStats: Equatable {
    let fastsCount: Int
    let total: TimeInterval
    let longest: TimeInterval
    let bestStreak: Int
    let since: Date?
    let lastSevenDays: [HistoryDay]

    static func compute(records: [FastRecord], now: Date = Date()) -> HistoryStats {
        let goalDays = Set(records.compactMap(\.goalDayKey))
        let historyGoalDays = Set(records.compactMap { record in
            record.goalReached ? Clock.dayKey(record.startDate) : nil
        })

        return HistoryStats(
            fastsCount: records.count,
            total: records.reduce(0) { $0 + $1.duration },
            longest: records.map(\.duration).max() ?? 0,
            bestStreak: longestRun(of: goalDays),
            since: records.map(\.startDate).min(),
            lastSevenDays: lastSeven(goalDays: historyGoalDays, now: now)
        )
    }

    static func showsFirstNote(fastsCount: Int, streakCount: Int) -> Bool {
        fastsCount <= 2 && streakCount <= fastsCount
    }

    static func monthGroups(records: [FastRecord]) -> [HistoryMonthGroup] {
        let calendar = Clock.gregorian
        let sorted = records.sorted { $0.startTimestamp > $1.startTimestamp }

        var order: [String] = []
        var buckets: [String: [FastRecord]] = [:]
        for record in sorted {
            let components = calendar.dateComponents([.year, .month], from: record.startDate)
            let key = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]?.append(record)
        }

        return order.compactMap { key in
            guard let records = buckets[key], let first = records.first else { return nil }
            let components = calendar.dateComponents([.year, .month], from: first.startDate)
            guard let month = calendar.date(from: components) else { return nil }
            return HistoryMonthGroup(id: key, month: month, records: records)
        }
    }

    // MARK: - Streak math

    private static func longestRun(of dayKeys: Set<String>) -> Int {
        guard !dayKeys.isEmpty else { return 0 }
        let sorted = dayKeys.sorted()
        var best = 1
        var run = 1
        for (previous, current) in zip(sorted, sorted.dropFirst()) {
            run = Clock.isDayBefore(previous, current) ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    private static func lastSeven(goalDays: Set<String>, now: Date) -> [HistoryDay] {
        let calendar = Clock.gregorian
        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return HistoryDay(date: day, reachedGoal: goalDays.contains(Clock.dayKey(day)))
        }
    }
}
