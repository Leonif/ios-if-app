//
//  HistoryStatsTests.swift
//  IFAppTests
//

import XCTest
@testable import IFApp

final class HistoryStatsTests: XCTestCase {

    func testFirstNoteHiddenWhenStreakOutrunsTheRecords() {
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 1, streakCount: 4))
    }

    func testFirstNoteHiddenWhenTheCarriedStreakHasLapsed() {
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 2, streakCount: 6))
    }

    func testFirstNoteShownForAFirstFastWithoutAGoal() {
        XCTAssertTrue(HistoryStats.showsFirstNote(fastsCount: 1, streakCount: 0))
    }

    func testFirstNoteShownForAFirstGoalDay() {
        XCTAssertTrue(HistoryStats.showsFirstNote(fastsCount: 1, streakCount: 1))
    }

    func testFirstNoteHiddenPastTwoRecords() {
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 3, streakCount: 0))
        XCTAssertFalse(HistoryStats.showsFirstNote(fastsCount: 3, streakCount: 3))
    }

    func testFirstNoteShownWithNoHistoryAndNoStreak() {
        XCTAssertTrue(HistoryStats.showsFirstNote(fastsCount: 0, streakCount: 0))
    }

    // MARK: - Month grouping

    func testMonthGroupIdIsTheGregorianMonth() {
        let groups = HistoryStats.monthGroups(records: [record(day: 11, month: 9, year: 2026)])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.id, "2026-09")
    }

    func testMonthGroupDateIsTheFirstDayOfTheGregorianMonth() {
        let groups = HistoryStats.monthGroups(records: [record(day: 11, month: 9, year: 2026)])
        let parts = Clock.gregorian.dateComponents([.year, .month, .day],
                                                   from: groups.first?.month ?? .distantPast)
        XCTAssertEqual(parts.year, 2026)
        XCTAssertEqual(parts.month, 9)
        XCTAssertEqual(parts.day, 1)
    }

    func testRecordsSplitOnGregorianMonthBoundaries() {
        let groups = HistoryStats.monthGroups(records: [
            record(day: 31, month: 8, year: 2026),
            record(day: 1, month: 9, year: 2026),
            record(day: 30, month: 9, year: 2026),
        ])
        XCTAssertEqual(groups.map(\.id), ["2026-09", "2026-08"])
        XCTAssertEqual(groups.first?.records.count, 2)
    }

    func testLastSevenDaysCarryDatesOldestToToday() {
        let now = Clock.gregorian.date(from: DateComponents(year: 2026, month: 9, day: 12, hour: 12))!
        let stats = HistoryStats.compute(records: [], now: now)

        XCTAssertEqual(stats.lastSevenDays.map(\.id), [
            "2026-09-06", "2026-09-07", "2026-09-08", "2026-09-09",
            "2026-09-10", "2026-09-11", "2026-09-12",
        ])
        XCTAssertEqual(stats.lastSevenDays.map(\.reachedGoal), Array(repeating: false, count: 7))
    }

    func testGoalDotUsesTheHistoryRowsStartDayForAnOvernightFast() {
        let calendar = Clock.gregorian
        let start = calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 8, hour: 19, minute: 25
        ))!
        let record = FastRecord(
            id: UUID(),
            startTimestamp: start.timeIntervalSince1970,
            endTimestamp: start.addingTimeInterval(18 * 3600 + 17 * 60).timeIntervalSince1970,
            goalHours: 16,
            planLabel: "16:8"
        )
        let now = calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 12, hour: 12
        ))!

        let stats = HistoryStats.compute(records: [record], now: now)
        let reachedDays = stats.lastSevenDays.filter(\.reachedGoal).map(\.id)

        XCTAssertEqual(reachedDays, ["2026-09-08"])
        XCTAssertEqual(record.goalDayKey, "2026-09-09")
    }

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

    private func record(duration: TimeInterval) -> FastRecord {
        let start = Date(timeIntervalSince1970: 1_750_000_000)
        return FastRecord(id: UUID(),
                          startTimestamp: start.timeIntervalSince1970,
                          endTimestamp: start.timeIntervalSince1970 + duration,
                          goalHours: 16,
                          planLabel: "16:8")
    }

    func testTotalNeverRendersBelowTheLongestFastItContains() {
        let sixteenOhOne: TimeInterval = 16 * 3600 + 60
        let stats = HistoryStats.compute(records: [record(duration: sixteenOhOne)])

        XCTAssertEqual(stats.total, stats.longest)
        XCTAssertEqual(HistoryFormat.duration(stats.total),
                       HistoryFormat.duration(stats.longest))
    }

    func testTotalIsTheSumOfEveryFastToTheSecond() {
        let stats = HistoryStats.compute(records: [
            record(duration: 16 * 3600 + 60),
            record(duration: 12 * 3600 + 1800),
        ])
        XCTAssertEqual(stats.total, 28 * 3600 + 1860)
        XCTAssertEqual(stats.longest, 16 * 3600 + 60)
    }

}
