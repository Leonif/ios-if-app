//
//  MealPickerTests.swift
//  IFAppTests
//
//  Guards the property the last-meal picker exists to have: the answer means the
//  same thing a minute later as it did when it was given.
//
//  It did not, and the way it failed is worth writing down, because the shape of the
//  bug is what the state shape is now chosen against. The picker used to store the
//  moment — "today, 23:00" — and re-derive the distance from it on every read. Cross
//  midnight with the sheet open, or simply leave a seeded value sitting there, and
//  "today 23:00" is an hour and a half into the *future*. The distance came back
//  negative, the clamp floored it at zero, and the screen said "Just now" over a fast
//  that would start at the moment of the tap. The user's answer was gone and nothing
//  on screen admitted it.
//
//  Storing the distance removes the failure rather than guarding it: there is no
//  re-derivation to go wrong. These tests are what keeps that true if anyone puts
//  the moment back.
//

import XCTest
@testable import IFApp

final class MealPickerTests: XCTestCase {

    // MARK: The midnight crossing

    /// 23:00 yesterday, read at 00:30. The distance is an hour and a half, and the
    /// clock time it resolves to is still 23:00 — on the previous day.
    func testMomentAcrossMidnightLandsOnYesterdayAtTheSameClockTime() {
        let moment = MealMath.moment(minutesAgo: 90, nowMinuteOfDay: 30)
        XCTAssertEqual(moment.ateDay, 1)
        XCTAssertEqual(moment.ateMin, 23 * 60)
    }

    /// The regression itself. The same answer is read twice, ten minutes apart, with
    /// midnight in between; the wall-clock moment it names must not move.
    ///
    /// Before the fix this could not even be expressed — the state held the moment,
    /// so "the same answer" after midnight was a different answer.
    func testTheSameAnswerNamesTheSameMomentOnBothSidesOfMidnight() {
        var state = MealState()
        // 23:50, answering "an hour ago" — so 22:50.
        state.set(minutesAgo: 60, chip: -1, via: .ribbon)
        let before = MealMath.moment(minutesAgo: state.minutesAgo, nowMinuteOfDay: 23 * 60 + 50)
        XCTAssertEqual(before.ateDay, 0)
        XCTAssertEqual(before.ateMin, 22 * 60 + 50)

        // Ten minutes later it is 00:00 the next day. Nothing was touched, so the
        // answer is still "60 minutes before the moment it is read".
        let after = MealMath.moment(minutesAgo: state.minutesAgo, nowMinuteOfDay: 0)
        XCTAssertEqual(after.ateDay, 1, "the meal is now on the previous calendar day")
        XCTAssertEqual(after.ateMin, 23 * 60, "and an hour before the new midnight")
        XCTAssertEqual(state.minutesAgo, 60, "the stored answer itself never moved")
    }

    /// A distance longer than the day it is read in must count whole days back, not
    /// wrap inside one. Three days and two hours, read at 01:00.
    func testMomentCountsWholeDaysBackRatherThanWrapping() {
        let moment = MealMath.moment(minutesAgo: 3 * 1440 + 120, nowMinuteOfDay: 60)
        XCTAssertEqual(moment.ateDay, 4)
        XCTAssertEqual(moment.ateMin, 23 * 60)
    }

    /// Exactly on a midnight boundary — the case floor division gets wrong when it
    /// is written as truncating division.
    func testMomentOnAnExactMidnightBoundary() {
        let moment = MealMath.moment(minutesAgo: 60, nowMinuteOfDay: 60)
        XCTAssertEqual(moment.ateDay, 0, "01:00 minus an hour is still today")
        XCTAssertEqual(moment.ateMin, 0)
    }

    // MARK: The domain, clamped in one place

    func testDistanceIsNeverNegative() {
        XCTAssertEqual(MealMath.clamped(-1), 0)
        XCTAssertEqual(MealMath.clamped(-10_000), 0)
    }

    func testDistanceStopsAtSevenDays() {
        XCTAssertEqual(MealScale.maxMinutes, 7 * 24 * 60)
        XCTAssertEqual(MealMath.clamped(7 * 1440 + 1), 7 * 1440)
        XCTAssertEqual(MealMath.clamped(90_000), 7 * 1440)
    }

    /// The clamp is on the way *into* the state, not only on the way out of it, so
    /// there is no reachable state that holds a value outside the domain.
    func testStateCannotHoldAValueOutsideTheDomain() {
        var state = MealState()
        state.set(minutesAgo: -500, chip: -1, via: .exact)
        XCTAssertEqual(state.minutesAgo, 0)
        state.set(minutesAgo: 99_999, chip: -1, via: .ribbon)
        XCTAssertEqual(state.minutesAgo, MealScale.maxMinutes)
    }

    // MARK: A fast never starts after it is started

    func testFastStartIsNeverInTheFuture() {
        let now = 1_760_000_000.0
        XCTAssertEqual(MealMath.fastStart(minutesAgo: 0, now: now), now)
        XCTAssertEqual(MealMath.fastStart(minutesAgo: -90, now: now), now,
                       "a negative distance is not a fast starting an hour and a half from now")
    }

    func testFastStartCountsBackFromTheMomentItIsAsked() {
        let now = 1_760_000_000.0
        XCTAssertEqual(MealMath.fastStart(minutesAgo: 90, now: now), now - 5400)
    }

    /// Both screens that turn a meal into a fast start go through one function, so
    /// the floor cannot be present on one path and missing on the other.
    func testFastStartFloorHoldsAtTheFarEndOfTheDomainToo() {
        let now = 1_760_000_000.0
        XCTAssertEqual(MealMath.fastStart(minutesAgo: 99_999, now: now),
                       now - Double(MealScale.maxMinutes) * 60)
    }

    // MARK: The scale

    /// The precision the card asks for: five minutes inside the first three hours,
    /// an hour at the far end.
    func testSnapResolutionByBand() {
        XCTAssertEqual(MealScale.step(at: 0), 5)
        XCTAssertEqual(MealScale.step(at: 179), 5)
        XCTAssertEqual(MealScale.step(at: 180), 15)
        XCTAssertEqual(MealScale.step(at: 719), 15)
        XCTAssertEqual(MealScale.step(at: 720), 30)
        XCTAssertEqual(MealScale.step(at: 1439), 30)
        XCTAssertEqual(MealScale.step(at: 1440), 60)
        XCTAssertEqual(MealScale.step(at: MealScale.maxMinutes), 60)
    }

    /// Position and snapping are inverses on the grid, in every band — otherwise the
    /// marker and the value disagree somewhere along the strip.
    func testPositionAndSnapAreInversesOnEveryStep() {
        for minutes in MealScale.stepMinutes {
            XCTAssertEqual(MealScale.snappedMinutes(atPosition: MealScale.position(ofMinutes: minutes)),
                           minutes, "round trip broke at \(minutes) minutes")
        }
    }

    func testTheStripEndsAtTheDomainLimit() {
        XCTAssertEqual(MealScale.stepMinutes.first, 0)
        XCTAssertEqual(MealScale.stepMinutes.last, MealScale.maxMinutes)
        XCTAssertEqual(MealScale.snappedMinutes(atPosition: MealScale.length + 500),
                       MealScale.maxMinutes, "dragging past the end holds at seven days")
    }

    // MARK: Which control answered

    func testEachControlReportsItself() {
        var state = MealState()
        XCTAssertEqual(state.inputMethod, .untouched)

        state.set(minutesAgo: 60, chip: MealChip.oneHour.rawValue, via: .chip)
        XCTAssertEqual(state.inputMethod, .chip)
        XCTAssertEqual(state.chipIdx, MealChip.oneHour.rawValue)

        state.set(minutesAgo: 95, chip: -1, via: .ribbon)
        XCTAssertEqual(state.inputMethod, .ribbon)
        XCTAssertEqual(state.chipIdx, -1, "dragging drops the lit pill")

        state.set(minutesAgo: 412, chip: -1, via: .exact)
        XCTAssertEqual(state.inputMethod, .exact)
    }

    /// Scrubbing back to zero is not an answer, it is a return to "now" — reporting
    /// it as a ribbon answer would count back-dates that did not happen.
    func testScrubbingBackToNowReportsAsUntouched() {
        var state = MealState()
        state.set(minutesAgo: 120, chip: -1, via: .ribbon)
        state.set(minutesAgo: 0, chip: -1, via: .ribbon)
        XCTAssertEqual(state.inputMethod, .untouched)
        XCTAssertTrue(state.isFresh)
    }

    /// The window-close default is the app's own value and says so, so the analytics
    /// can tell it apart from a chip the user actually tapped.
    func testTheSeededValueIsMarkedAsSeeded() {
        var state = MealState()
        state.set(minutesAgo: 200, chip: -1, via: .seeded)
        XCTAssertEqual(state.inputMethod, .seeded)
        XCTAssertEqual(state.inputMethod.rawValue, "seeded")
    }

    /// The raw values are a GA4 dimension's vocabulary — renaming one silently
    /// splits a year of reports in two.
    func testInputMethodVocabularyIsFixed() {
        XCTAssertEqual(MealInputMethod.chip.rawValue, "chip")
        XCTAssertEqual(MealInputMethod.ribbon.rawValue, "ribbon")
        XCTAssertEqual(MealInputMethod.exact.rawValue, "exact")
        XCTAssertEqual(MealInputMethod.untouched.rawValue, "untouched")
    }

    // MARK: The reducer

    func testSeedDoesNotOverwriteAnAnswerAlreadyGiven() {
        var state = mealReducer(state: MealState(), action: MealAction.chipPicked(
            idx: MealChip.threeHours.rawValue, minutesAgo: 180))
        state = mealReducer(state: state, action: MealAction.initialized(minutesAgo: 900))
        XCTAssertEqual(state.minutesAgo, 180, "the seed lost to the tap, as it must")
        XCTAssertEqual(state.inputMethod, .chip)
    }

    func testSeedLandsWhileNothingHasBeenChosen() {
        let state = mealReducer(state: MealState(), action: MealAction.initialized(minutesAgo: 900))
        XCTAssertEqual(state.minutesAgo, 900)
        XCTAssertEqual(state.chipIdx, -1)
    }

    func testClearingReturnsToNowAndLightsTheFirstChip() {
        var state = mealReducer(state: MealState(), action: MealAction.scrubbed(minutesAgo: 700))
        state = mealReducer(state: state, action: MealAction.cleared)
        XCTAssertTrue(state.isFresh)
        XCTAssertEqual(state.chipIdx, MealChip.justNow.rawValue)
        XCTAssertEqual(state.inputMethod, .untouched)
    }

    // MARK: "Last night"

    /// One rule for all twenty-four hours: the most recent 9 PM that has passed.
    func testLastNightIsTheMostRecentEveningThatHasPassed() {
        // 03:00 — last night was six hours ago.
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 3 * 60), 6 * 60)
        // 14:00 — seventeen hours back to yesterday evening.
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 14 * 60), 17 * 60)
    }

    /// Just after 9 PM the nearest past evening is tonight, minutes ago, and calling
    /// that "last night" would be nonsense — so it steps back a day.
    func testLastNightStepsBackWhenTonightHasOnlyJustBecomeEvening() {
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 21 * 60 + 10),
                       10 + 1440)
        // And half an hour past the floor it is a normal, short "last night".
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 21 * 60 + 40), 40)
    }
}
