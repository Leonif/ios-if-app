//
//  StreakFreezeTests.swift
//  IFAppTests
//
//  The protected day — one missed day per calendar month, kept from breaking a run,
//  for Pro only. It is sold by name on the offer screen and in three store texts, so
//  the two halves it is sold as are both held here: the run survives one missed day,
//  and buying Pro during the day a break became visible undoes that break (edge 8).
//
//  Two surfaces, one rule. `StreakStatus.freezeCovers` decides, the reducer debits
//  the month, and `displayed(at:)` is what the user actually sees — a rule that held
//  in the reducer alone would still show a run dropping to zero for a day and coming
//  back, which is the thing being sold against.
//

import XCTest
import Redux
@testable import IFApp

final class StreakFreezeTests: XCTestCase {

    // MARK: Fixtures

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private func key(_ y: Int, _ m: Int, _ d: Int) -> String {
        Clock.dayKey(day(y, m, d))
    }

    /// A run of `count` days whose last goal landed on `last`, mid-cycle and settled.
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

    // MARK: The rule in the reducer

    /// One missed day, Pro, nothing spent yet: the run carries on and the month pays.
    func testOneMissedDayIsCoveredForPro() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 3), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 7)
        XCTAssertEqual(after.lastGoalDate, key(2026, 8, 3))
        // Charged to the month of the *missed* day (2 August), not of the goal.
        XCTAssertEqual(after.freezeSpentMonth, "2026-08")
    }

    /// Without the entitlement nothing changed: a missed day is still a hard reset,
    /// and no month is charged for a benefit that was never held.
    func testOneMissedDayStillResetsWithoutPro() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 3), ownsFreeze: false)

        XCTAssertEqual(after.streakCount, 1)
        XCTAssertNil(after.freezeSpentMonth)
    }

    /// One protected day protects one day. Two in a row is a reset for everyone, and
    /// the allowance is left untouched for the month it may still be needed in.
    func testTwoMissedDaysResetEvenForPro() {
        let state = streakState(count: 12, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 4), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 1)
        XCTAssertNil(after.freezeSpentMonth)
    }

    /// One per calendar month means the second gap in the same month is a reset.
    func testSecondMissedDayInSameMonthResets() {
        let state = streakState(count: 4, last: key(2026, 8, 10), freezeSpentMonth: "2026-08")
        let after = celebrate(state, on: key(2026, 8, 12), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 1)
        XCTAssertEqual(after.freezeSpentMonth, "2026-08")
    }

    /// The allowance is a calendar month, not a rolling thirty days: a gap in
    /// September is covered however late in August the last one was.
    func testNewCalendarMonthRestoresTheAllowance() {
        let state = streakState(count: 9, last: key(2026, 9, 1), freezeSpentMonth: "2026-08")
        let after = celebrate(state, on: key(2026, 9, 3), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 10)
        XCTAssertEqual(after.freezeSpentMonth, "2026-09")
    }

    /// The month boundary sits under the missed day, not under the goal that banks
    /// it: a day missed on 31 August is August's, so 1 September is still free — and
    /// a gap a few days later that month is duly covered by it.
    func testMissedDayOnTheLastOfTheMonthIsChargedToThatMonth() {
        let state = streakState(count: 3, last: key(2026, 8, 30))
        let afterGap = celebrate(state, on: key(2026, 9, 1), ownsFreeze: true)

        XCTAssertEqual(afterGap.streakCount, 4)
        XCTAssertEqual(afterGap.freezeSpentMonth, "2026-08")

        // September's own allowance is intact. The next fast clears `hasCelebrated`,
        // which is what lets a second goal moment through at all.
        var nextCycle = afterGap
        nextCycle.hasCelebrated = false
        let afterSecondGap = celebrate(nextCycle, on: key(2026, 9, 3), ownsFreeze: true)
        XCTAssertEqual(afterSecondGap.streakCount, 5)
        XCTAssertEqual(afterSecondGap.freezeSpentMonth, "2026-09")
    }

    /// The first day of a new month with the previous month's allowance spent is the
    /// mirror of the case above, and the one a rolling window would get wrong.
    func testFirstDayOfNewMonthIsCoveredAfterAugustWasSpent() {
        let state = streakState(count: 5, last: key(2026, 8, 31), freezeSpentMonth: "2026-08")
        let after = celebrate(state, on: key(2026, 9, 2), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 6)
        XCTAssertEqual(after.freezeSpentMonth, "2026-09")
    }

    /// An unbroken run spends nothing — the allowance is for gaps, and a Pro user who
    /// never misses a day still has it when they finally do.
    func testConsecutiveDayDoesNotSpendTheFreeze() {
        let state = streakState(count: 2, last: key(2026, 8, 1))
        let after = celebrate(state, on: key(2026, 8, 2), ownsFreeze: true)

        XCTAssertEqual(after.streakCount, 3)
        XCTAssertNil(after.freezeSpentMonth)
    }

    // MARK: What the user sees during the gap day

    /// The promise as it is sold: on the day after a missed one, the run still reads
    /// whole for a Pro user, and reads zero for everyone else.
    func testGapDayReadsWholeForProAndBrokenForFree() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        let now = day(2026, 8, 3)

        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: now), 6)
        XCTAssertEqual(state.streak(ownsFreeze: false).displayed(at: now), 0)
    }

    /// Beyond one missed day the entitlement changes nothing, on screen as in state.
    func testTwoMissedDaysReadZeroEvenForPro() {
        let state = streakState(count: 6, last: key(2026, 8, 1))
        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: day(2026, 8, 4)), 0)
    }

    /// A spent month shows the break it can no longer cover.
    func testSpentMonthReadsBrokenOnTheGapDay() {
        let state = streakState(count: 6, last: key(2026, 8, 10), freezeSpentMonth: "2026-08")
        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: day(2026, 8, 12)), 0)
    }

    // MARK: Edge 8 — buying within 24 hours of the break

    /// The break becomes visible at midnight starting the day after the missed one:
    /// through the missed day itself the run still counts as extended yesterday.
    private func breakInstant(afterLastGoal last: Date) -> Date {
        let visible = Calendar.current.date(byAdding: .day, value: 2, to: last)!
        return Calendar.current.startOfDay(for: visible)
    }

    /// Bought at the 23rd hour after the break: the run the purchase was made for is
    /// whole again, with no action from the user and no sheet in between.
    func testPurchaseAtHour23RestoresTheBrokenRun() {
        let last = day(2026, 8, 1)
        let state = streakState(count: 6, last: Clock.dayKey(last))
        let boughtAt = breakInstant(afterLastGoal: last).addingTimeInterval(23 * 3600)

        // Before the purchase this is exactly a broken run.
        XCTAssertEqual(state.streak(ownsFreeze: false).displayed(at: boughtAt), 0)
        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: boughtAt), 6)

        // And the next goal banks it rather than starting over.
        let after = celebrate(state, on: Clock.dayKey(boughtAt), ownsFreeze: true)
        XCTAssertEqual(after.streakCount, 7)
        XCTAssertEqual(after.freezeSpentMonth, "2026-08")
    }

    /// The 25th hour is past the window: a second day has now been missed, and no
    /// purchase reaches back that far.
    func testPurchaseAtHour25DoesNotRestoreTheBrokenRun() {
        let last = day(2026, 8, 1)
        let state = streakState(count: 6, last: Clock.dayKey(last))
        let boughtAt = breakInstant(afterLastGoal: last).addingTimeInterval(25 * 3600)

        XCTAssertEqual(state.streak(ownsFreeze: true).displayed(at: boughtAt), 0)

        let after = celebrate(state, on: Clock.dayKey(boughtAt), ownsFreeze: true)
        XCTAssertEqual(after.streakCount, 1)
        XCTAssertNil(after.freezeSpentMonth)
    }

    // MARK: State that predates the feature

    /// An install updating into 1.5.0 has no stored month, which reads as "unspent" —
    /// someone who just paid gets the benefit, not a month of waiting for it.
    func testAbsentStoredMonthCountsAsUnspent() {
        XCTAssertNil(TimerState().freezeSpentMonth)
        let state = streakState(count: 1, last: key(2026, 8, 1))
        XCTAssertTrue(state.streak(ownsFreeze: true).freezeCovers(key(2026, 8, 3)))
    }
}
