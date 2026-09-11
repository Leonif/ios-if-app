//
//  HistoryStatsTests.swift
//  IFAppTests
//
//  TF-1: the summary card was greeting everyone who updated from 1.4.4 as a
//  first-timer, because the beginner's note counted records while the number above it
//  came from the streak counter. The matrix below is the rule that replaced it, and
//  the first case is the defect itself.
//

import XCTest
@testable import IFApp

final class HistoryStatsTests: XCTestCase {

    /// The defect. One record, a streak carried over from 1.4.4: the counter knows
    /// four days the history has never heard of, so the card must not call this a
    /// first fast.
    func testFirstNoteHiddenWhenStreakOutrunsTheRecords() {
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 1, streakCount: 4))
    }

    /// A lapsed carry-over streak displays as 0, and its owner is still not a beginner.
    /// The rule reads the raw counter for exactly this case.
    func testFirstNoteHiddenWhenTheCarriedStreakHasLapsed() {
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 2, streakCount: 6))
    }

    /// The ordinary first fast, goal missed: no counter, one record, the note is the
    /// whole point of the card at that moment.
    func testFirstNoteShownForAFirstFastWithoutAGoal() {
        XCTAssertTrue(HistoryStats.showsFirstNote(fastsCount: 1, streakCount: 0))
    }

    /// The ordinary first fast, goal reached: streak of one, one record. Nothing
    /// contradicts anything, and the note stays — this is the path the copy was
    /// written for, and the fix must not take it away.
    func testFirstNoteShownForAFirstGoalDay() {
        XCTAssertTrue(HistoryStats.showsFirstNote(fastsCount: 1, streakCount: 1))
    }

    /// Past two records the note is gone regardless of the streak — the threshold that
    /// was already there is unchanged.
    func testFirstNoteHiddenPastTwoRecords() {
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 3, streakCount: 0))
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 3, streakCount: 3))
    }

    /// Nothing at all: the card is not shown at zero records, but the rule should not
    /// be the reason — it answers for the empty case too.
    func testFirstNoteShownWithNoHistoryAndNoStreak() {
        XCTAssertTrue(HistoryStats.showsFirstNote(fastsCount: 0, streakCount: 0))
    }

    // MARK: Month grouping (SU-6)

    /// The month a record is filed under is a **Gregorian** month, whatever calendar
    /// the device runs on. Taken from `Calendar.current`, an Arabic device grouped by
    /// Hijri months and the id read "1448-03"; the header then printed that month's
    /// first day through the Gregorian formatter and September records stood under
    /// "أغسطس 2026".
    func testMonthGroupIdIsTheGregorianMonth() {
        let groups = HistoryStats.monthGroups(records: [record(day: 11, month: 9, year: 2026)])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.id, "2026-09")
    }

    /// And the date behind the header is the first day of that same Gregorian month —
    /// the value `HistoryFormat.monthTitle` formats. The bug lived in this step: the
    /// first day of the Hijri month containing 11 September 2026 falls in August.
    func testMonthGroupDateIsTheFirstDayOfTheGregorianMonth() {
        let groups = HistoryStats.monthGroups(records: [record(day: 11, month: 9, year: 2026)])
        let parts = Clock.gregorian.dateComponents([.year, .month, .day],
                                                   from: groups.first?.month ?? .distantPast)
        XCTAssertEqual(parts.year, 2026)
        XCTAssertEqual(parts.month, 9)
        XCTAssertEqual(parts.day, 1)
    }

    /// Two Gregorian months, two groups, newest first — the Hijri buckets cut the same
    /// records in different places, so the count is part of the claim.
    func testRecordsSplitOnGregorianMonthBoundaries() {
        let groups = HistoryStats.monthGroups(records: [
            record(day: 31, month: 8, year: 2026),
            record(day: 1, month: 9, year: 2026),
            record(day: 30, month: 9, year: 2026),
        ])
        XCTAssertEqual(groups.map(\.id), ["2026-09", "2026-08"])
        XCTAssertEqual(groups.first?.records.count, 2)
    }

    /// A 14-hour fast starting at noon on the given Gregorian day.
    private func record(day: Int, month: Int, year: Int) -> FastRecord {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let start = Clock.gregorian.date(from: components) ?? Date()
        return FastRecord(id: UUID(),
                          startTimestamp: start.timeIntervalSince1970,
                          endTimestamp: start.timeIntervalSince1970 + 14 * 3600,
                          goalHours: 16,
                          planLabel: "16:8")
    }

    /// A fast of an exact length, starting at a fixed moment — the totals do not care
    /// when it ran, only how long.
    private func record(duration: TimeInterval) -> FastRecord {
        let start = Date(timeIntervalSince1970: 1_750_000_000)
        return FastRecord(id: UUID(),
                          startTimestamp: start.timeIntervalSince1970,
                          endTimestamp: start.timeIntervalSince1970 + duration,
                          goalHours: 16,
                          planLabel: "16:8")
    }

    /// SU-13. The summary card prints `TOTAL` and `LONGEST` side by side, and a sum
    /// truncated to whole hours printed below the single fast it was made of: one
    /// 16h 01m fast read "TOTAL 16h · LONGEST 16h 01m". The invariant is asserted on
    /// the rendered strings, not on the numbers — the numbers were never wrong, the
    /// two granularities were.
    func testTotalNeverRendersBelowTheLongestFastItContains() {
        let sixteenOhOne: TimeInterval = 16 * 3600 + 60
        let stats = HistoryStats.compute(records: [record(duration: sixteenOhOne)])

        XCTAssertEqual(stats.total, stats.longest)
        XCTAssertEqual(HistoryFormat.duration(stats.total),
                       HistoryFormat.duration(stats.longest))
    }

    /// And the sum still adds up once there is more than one fast in it.
    func testTotalIsTheSumOfEveryFastToTheSecond() {
        let stats = HistoryStats.compute(records: [
            record(duration: 16 * 3600 + 60),
            record(duration: 12 * 3600 + 1800),
        ])
        XCTAssertEqual(stats.total, 28 * 3600 + 1860)
        XCTAssertEqual(stats.longest, 16 * 3600 + 60)
    }

}
