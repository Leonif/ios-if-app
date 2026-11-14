//
//  StreakFreezeTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class StreakFreezeTests: XCTestCase {

    // MARK: - Fixtures

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private func key(_ y: Int, _ m: Int, _ d: Int) -> String {
        Clock.dayKey(day(y, m, d))
    }

    private func streakState(count: Int, last: String, freezeSpentMonth: String? = nil) -> TimerState {
        var state = TimerState()
        state.fastStartTimestamp = 1
        state.isRunning = true
        state.streakCount = count
        state.lastGoalDate = last
        state.freezeSpentMonth = freezeSpentMonth
        return state
    }

    private func celebrate(_ state: TimerState, on dayKey: String, ownsFreeze: Bool) -> TimerState {
        timerReducer(state: state,
                     action: TimerAction.goalCelebrated(dayKey: dayKey, ownsFreeze: ownsFreeze))
    }

    // MARK: - The rule in the reducer

    func testOneMissedDayIsCoveredForPro() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 3), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 7)
        XCTAssertEqual(after.lastGoalDate, key(2026, 8, 3))
        XCTAssertEqual(after.freezeSpentMonth, "2026-08")
    }

    func testOneMissedDayStillResetsWithoutPro() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 3), ownsFreeze: false)

        XCTAssertEqual(after.streakCount, 1)
        XCTAssertNil(after.freezeSpentMonth)
    }

    func testTwoMissedDaysResetEvenForPro() {
        let state = streakState(count: 12, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 4), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 1)
        XCTAssertNil(after.freezeSpentMonth)
    }

    func testSecondMissedDayInSameMonthResets() {
        let state = streakState(count: 4, last: key(2026, 8, 10), freezeSpentMonth: "2026-08")
        let after = celebrate(state, on: key(2026, 8, 12), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 1)
        XCTAssertEqual(after.freezeSpentMonth, "2026-08")
    }

    func testNewCalendarMonthRestoresTheAllowance() {
        let state = streakState(count: 9, last: key(2026, 9, 1), freezeSpentMonth: "2026-08")
        let after = celebrate(state, on: key(2026, 9, 3), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 10)
        XCTAssertEqual(after.freezeSpentMonth, "2026-09")
    }

    func testMissedDayOnTheLastOfTheMonthIsChargedToThatMonth() {
        let state = streakState(count: 3, last: key(2026, 8, 30))
        let afterGap = celebrate(state, on: key(2026, 9, 1), ownsFreeze: true)

        XCTAssertEqual(afterGap.streakCount, 4)
        XCTAssertEqual(afterGap.freezeSpentMonth, "2026-08")

        var nextCycle = afterGap
        nextCycle.hasCelebrated = false
        let afterSecondGap = celebrate(nextCycle, on: key(2026, 9, 3), ownsFreeze: true)
        XCTAssertEqual(afterSecondGap.streakCount, 5)
        XCTAssertEqual(afterSecondGap.freezeSpentMonth, "2026-09")
    }

    func testFirstDayOfNewMonthIsCoveredAfterAugustWasSpent() {
        let state = streakState(count: 5, last: key(2026, 8, 31), freezeSpentMonth: "2026-08")
        let after = celebrate(state, on: key(2026, 9, 2), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 6)
        XCTAssertEqual(after.freezeSpentMonth, "2026-09")
    }

    func testConsecutiveDayDoesNotSpendTheFreeze() {
        let state = streakState(count: 2, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 2), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 3)
        XCTAssertNil(after.freezeSpentMonth)
    }

    // MARK: - What the user sees during the gap day

    func testGapDayReadsWholeForProAndBrokenForFree() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        let now = day(2026, 8, 3)

        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: now), 6)
        XCTAssertEqual(state.streak(ownsFreeze: false).displayed(at: now), 0)
    }

    func testTwoMissedDaysReadZeroEvenForPro() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: day(2026, 8, 4)), 0)
    }

    func testSpentMonthReadsBrokenOnTheGapDay() {
        let state = streakState(count: 6, last: key(2026, 8, 10), freezeSpentMonth: "2026-08")
        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: day(2026, 8, 12)), 0)
    }

    func testBrokenRunCarriesItsLastGoalDate() {
        let lastGoal = key(2026, 8, 10)
        let state = streakState(count: 5, last: lastGoal)

        XCTAssertEqual(state.streak(ownsFreeze: false).display(at: day(2026, 8, 12)),
                       .justEnded(5, lastGoalDate: lastGoal))
    }

    // MARK: - Edge 8 — buying within 24 hours of the break

    private func breakInstant(afterLastGoal last: Date) -> Date {
        let visible = Calendar.current.date(byAdding: .day, value: 2, to: last)!
        return Calendar.current.startOfDay(for: visible)
    }

    func testPurchaseAtHour23RestoresTheBrokenRun() {
        let last = day(2026, 8, 1)
        let state = streakState(count: 6, last: Clock.dayKey(last))
        let boughtAt = breakInstant(afterLastGoal: last).addingTimeInterval(23 * 3600)

        XCTAssertEqual(state.streak(ownsFreeze: false).displayed(at: boughtAt), 0)
        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: boughtAt), 6)

        let after = celebrate(state, on: Clock.dayKey(boughtAt), ownsFreeze: true)
        XCTAssertEqual(after.streakCount, 7)
        XCTAssertEqual(after.freezeSpentMonth, "2026-08")
    }

    func testPurchaseAtHour25DoesNotRestoreTheBrokenRun() {
        let last = day(2026, 8, 1)
        let state = streakState(count: 6, last: Clock.dayKey(last))
        let boughtAt = breakInstant(afterLastGoal: last).addingTimeInterval(25 * 3600)

        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: boughtAt), 0)

        let after = celebrate(state, on: Clock.dayKey(boughtAt), ownsFreeze: true)
        XCTAssertEqual(after.streakCount, 1)
        XCTAssertNil(after.freezeSpentMonth)
    }

    // MARK: - State that predates the feature

    func testAbsentStoredMonthCountsAsUnspent() {
        XCTAssertNil(TimerState().freezeSpentMonth)
        let state = streakState(count: 1, last: key(2026, 8, 1))
        XCTAssertTrue(state.streak(ownsFreeze: true).freezeCovers(key(2026, 8, 3)))
    }
}
