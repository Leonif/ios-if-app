//
//  MealPickerTests.swift
//  IFAppTests
//

import XCTest
@testable import IFApp

final class MealPickerTests: XCTestCase {

    // MARK: - The midnight crossing

    func testMomentAcrossMidnightLandsOnYesterdayAtTheSameClockTime() {
        let moment = MealMath.moment(minutesAgo: 90, nowMinuteOfDay: 30)
        XCTAssertEqual(moment.ateDay, 1)
        XCTAssertEqual(moment.ateMin, 23 * 60)
    }

    func testTheSameAnswerNamesTheSameMomentOnBothSidesOfMidnight() {
        var state = MealState()
        state.set(minutesAgo: 60, chip: -1, via: .ribbon)
        let before = MealMath.moment(minutesAgo: state.minutesAgo, nowMinuteOfDay: 23 * 60 + 50)
        XCTAssertEqual(before.ateDay, 0)
        XCTAssertEqual(before.ateMin, 22 * 60 + 50)

        let after = MealMath.moment(minutesAgo: state.minutesAgo, nowMinuteOfDay: 0)
        XCTAssertEqual(after.ateDay, 1, "the meal is now on the previous calendar day")
        XCTAssertEqual(after.ateMin, 23 * 60, "and an hour before the new midnight")
        XCTAssertEqual(state.minutesAgo, 60, "the stored answer itself never moved")
    }

    func testMomentCountsWholeDaysBackRatherThanWrapping() {
        let moment = MealMath.moment(minutesAgo: 3 * 1440 + 120, nowMinuteOfDay: 60)
        XCTAssertEqual(moment.ateDay, 4)
        XCTAssertEqual(moment.ateMin, 23 * 60)
    }

    func testMomentOnAnExactMidnightBoundary() {
        let moment = MealMath.moment(minutesAgo: 60, nowMinuteOfDay: 60)
        XCTAssertEqual(moment.ateDay, 0, "01:00 minus an hour is still today")
        XCTAssertEqual(moment.ateMin, 0)
    }

    // MARK: - The domain, clamped in one place

    func testDistanceIsNeverNegative() {
        XCTAssertEqual(MealMath.clamped(-1), 0)
        XCTAssertEqual(MealMath.clamped(-10_000), 0)
    }

    func testDistanceStopsAtSevenDays() {
        XCTAssertEqual(MealScale.maxMinutes, 7 * 24 * 60)
        XCTAssertEqual(MealMath.clamped(7 * 1440 + 1), 7 * 1440)
        XCTAssertEqual(MealMath.clamped(90_000), 7 * 1440)
    }

    func testStateCannotHoldAValueOutsideTheDomain() {
        var state = MealState()
        state.set(minutesAgo: -500, chip: -1, via: .exact)
        XCTAssertEqual(state.minutesAgo, 0)
        state.set(minutesAgo: 99_999, chip: -1, via: .ribbon)
        XCTAssertEqual(state.minutesAgo, MealScale.maxMinutes)
    }

    // MARK: - A fast never starts after it is started

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

    func testFastStartFloorHoldsAtTheFarEndOfTheDomainToo() {
        let now = 1_760_000_000.0
        XCTAssertEqual(MealMath.fastStart(minutesAgo: 99_999, now: now),
                       now - Double(MealScale.maxMinutes) * 60)
    }

    // MARK: - The scale

    func testSnapIsOneMinuteAcrossTheWholeDomain() {
        for m in [1, 42, 137, 730, 731, 4319, 6000, MealScale.maxMinutes - 1] {
            XCTAssertEqual(MealScale.snap(m), m, "minute \(m) should land on itself")
        }
        XCTAssertEqual(MealScale.step(at: 0), 15)
        XCTAssertEqual(MealScale.step(at: MealScale.maxMinutes), 15)
    }

    func testPositionIsLinearInMinutes() {
        XCTAssertEqual(MealScale.position(ofMinutes: 0), 0)
        XCTAssertEqual(MealScale.position(ofMinutes: 1), MealScale.pitch)
        XCTAssertEqual(MealScale.position(ofMinutes: 720), 720 * MealScale.pitch)
        XCTAssertEqual(MealScale.position(ofMinutes: MealScale.maxMinutes), MealScale.length)
    }

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

    // MARK: - Which control answered

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

    func testScrubbingBackToNowReportsAsUntouched() {
        var state = MealState()
        state.set(minutesAgo: 120, chip: -1, via: .ribbon)
        state.set(minutesAgo: 0, chip: -1, via: .ribbon)
        XCTAssertEqual(state.inputMethod, .untouched)
        XCTAssertTrue(state.isFresh)
    }

    func testTheSeededValueIsMarkedAsSeeded() {
        var state = MealState()
        state.set(minutesAgo: 200, chip: -1, via: .seeded)
        XCTAssertEqual(state.inputMethod, .seeded)
        XCTAssertEqual(state.inputMethod.rawValue, "seeded")
    }

    func testInputMethodVocabularyIsFixed() {
        XCTAssertEqual(MealInputMethod.chip.rawValue, "chip")
        XCTAssertEqual(MealInputMethod.ribbon.rawValue, "ribbon")
        XCTAssertEqual(MealInputMethod.exact.rawValue, "exact")
        XCTAssertEqual(MealInputMethod.untouched.rawValue, "untouched")
    }

    // MARK: - The reducer

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

    // MARK: - Dismiss = cancel

    func testDismissingThePickerPutsTheAnswerBack() {
        var state = mealReducer(state: MealState(), action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.chipPicked(idx: MealChip.lastNight.rawValue,
                                                                       minutesAgo: 1369))
        XCTAssertEqual(state.minutesAgo, 1369, "the sheet applies as it is edited — that part is by design")

        state = mealReducer(state: state, action: MealAction.pickerDismissed)
        XCTAssertTrue(state.isFresh)
        XCTAssertEqual(state.chipIdx, MealChip.justNow.rawValue)
        XCTAssertEqual(state.inputMethod, .untouched)
    }

    func testDismissingOverASeededValueKeepsTheSeed() {
        var state = mealReducer(state: MealState(), action: MealAction.initialized(minutesAgo: 240))
        state = mealReducer(state: state, action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 900))
        state = mealReducer(state: state, action: MealAction.pickerDismissed)

        XCTAssertEqual(state.minutesAgo, 240)
        XCTAssertEqual(state.inputMethod, .seeded)
        XCTAssertEqual(state.chipIdx, -1)
    }

    func testConfirmingKeepsTheAnswerTheSheetWasClosedOn() {
        var state = mealReducer(state: MealState(), action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 315))
        state = mealReducer(state: state, action: MealAction.pickerConfirmed)

        XCTAssertEqual(state.minutesAgo, 315)
        XCTAssertEqual(state.inputMethod, .ribbon)
    }

    func testADismissAfterAConfirmCannotUndoTheCommittedAnswer() {
        var state = mealReducer(state: MealState(), action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 315))
        state = mealReducer(state: state, action: MealAction.pickerConfirmed)
        state = mealReducer(state: state, action: MealAction.pickerDismissed)

        XCTAssertEqual(state.minutesAgo, 315, "the confirmed answer stands")
    }

    func testASecondOpenTakesAFreshRestorePoint() {
        var state = mealReducer(state: MealState(), action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 120))
        state = mealReducer(state: state, action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 900))
        state = mealReducer(state: state, action: MealAction.pickerDismissed)

        XCTAssertEqual(state.minutesAgo, 120)
    }

    func testASpentRestorePointIsNotReused() {
        var state = mealReducer(state: MealState(), action: MealAction.pickerOpened)
        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 120))
        state = mealReducer(state: state, action: MealAction.pickerDismissed)
        XCTAssertTrue(state.isFresh)

        state = mealReducer(state: state, action: MealAction.scrubbed(minutesAgo: 300))
        state = mealReducer(state: state, action: MealAction.pickerDismissed)
        XCTAssertEqual(state.minutesAgo, 300, "no restore point, so nothing to put back")
    }

    // MARK: - "Last night"

    func testLastNightIsTheMostRecentEveningThatHasPassed() {
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 3 * 60), 6 * 60)
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 14 * 60), 17 * 60)
    }

    func testLastNightStepsBackWhenTonightHasOnlyJustBecomeEvening() {
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 21 * 60 + 10),
                       10 + 1440)
        XCTAssertEqual(PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay: 21 * 60 + 40), 40)
    }
}
