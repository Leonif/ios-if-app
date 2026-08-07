//
//  HistoryStats.swift
//  IFApp
//
//  Every number on the history screen is a pure function of the full record array,
//  computed at render. No incremental counters: a running `total += duration` is
//  what makes deletion expensive and lets the displayed totals drift from the data.
//  At a few thousand records this is microseconds.
//
//  A future paywall may hide *rows* beyond a window — it must never narrow the
//  input here. Totals that shrink the day a paywall lands read as a bug, or worse,
//  as something taken away.
//

import Foundation

/// One month's worth of records, newest month first.
struct HistoryMonthGroup: Identifiable, Equatable {
    /// "2026-07" — stable across locales, used only as identity.
    let id: String
    /// First day of the month, for the localized header title.
    let month: Date
    let records: [FastRecord]

    var totalHours: Int {
        Int(records.reduce(0) { $0 + $1.duration } / 3600)
    }
}

struct HistoryStats: Equatable {
    let fastsCount: Int
    let totalHours: Int
    let longest: TimeInterval
    /// Longest run of consecutive goal days found in the history.
    let bestStreak: Int
    /// When the history begins — the "since" in "Best 9 · since 12 March".
    let since: Date?
    /// Goal reached on each of the last 7 local days, oldest first.
    let lastSevenDays: [Bool]

    static func compute(records: [FastRecord], now: Date = Date()) -> HistoryStats {
        let goalDays = Set(records.compactMap(\.goalDayKey))

        return HistoryStats(
            fastsCount: records.count,
            totalHours: Int(records.reduce(0) { $0 + $1.duration } / 3600),
            longest: records.map(\.duration).max() ?? 0,
            bestStreak: longestRun(of: goalDays),
            since: records.map(\.startDate).min(),
            lastSevenDays: lastSeven(goalDays: goalDays, now: now)
        )
    }

    /// Whether the summary card may greet the reader as a beginner.
    ///
    /// The card holds two numbers that come from different stores: the streak counter
    /// lives in the timer's persisted defaults and shipped in 1.4.4, the records live
    /// in a file and shipped in 1.4.5, and nothing backfilled one from the other.
    /// Counting only records, the card welcomed everyone who updated from 1.4.4 as a
    /// first-timer while a four-day streak stood above the sentence (TF-1).
    ///
    /// So the note is gated on both: it appears while the history is short *and* the
    /// counter claims nothing the records cannot account for. That keeps the ordinary
    /// first fast — one record, streak of one — exactly as it was, and it takes the
    /// raw counter rather than `displayed(at:)` on purpose: a streak that lapsed
    /// yesterday displays as 0, and it is still not the streak of a beginner.
    static func showsFirstNote(fastsCount: Int, streakCount: Int) -> Bool {
        fastsCount <= 2 && streakCount <= fastsCount
    }

    /// Records grouped by the month they *started* in — the row shows its start date,
    /// so a fast crossing a month boundary belongs to the month the user sees on it.
    static func monthGroups(records: [FastRecord]) -> [HistoryMonthGroup] {
        let calendar = Calendar.current
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

    // MARK: Streak math

    /// The longest chain of consecutive calendar days present in the set.
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

    /// Seven flags, oldest first: did a fast reach its goal on that local day.
    private static func lastSeven(goalDays: Set<String>, now: Date) -> [Bool] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { daysAgo in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return false }
            return goalDays.contains(Clock.dayKey(day))
        }
    }
}
