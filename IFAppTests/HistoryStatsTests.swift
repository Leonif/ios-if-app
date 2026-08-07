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
}
