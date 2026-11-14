//
//  OfferPhaseTests.swift
//  IFAppTests
//

import XCTest
@testable import IFApp

final class OfferPhaseTests: XCTestCase {

    private let now: Double = 1_800_000_000

    private func state(_ timer: TimerState, planHours: Int = 16) -> AppState {
        var state = AppState()
        state.timerState = timer
        state.planState = PlanState(plan: Plan(hours: planHours))
        return state
    }

    private func running(hours: Double) -> AppState {
        state(TimerState(fastStartTimestamp: now - hours * 3600, isRunning: true))
    }

    func testRunningFastTakesThePhaseItIsIn() {
        XCTAssertEqual(running(hours: 1).offerPhase(at: now), .fed)
        XCTAssertEqual(running(hours: 5).offerPhase(at: now), .sugar)
        XCTAssertEqual(running(hours: 9).offerPhase(at: now), .fat)
        XCTAssertEqual(running(hours: 13).offerPhase(at: now), .ketosis)
        XCTAssertEqual(running(hours: 17).offerPhase(at: now), .autophagy)
    }

    func testPinnedGoalDecidesThePhaseNotTheSelectedPlan() {
        let pinned = state(TimerState(fastStartTimestamp: now - 13 * 3600, goalHours: 20, isRunning: true),
                           planHours: 12)
        XCTAssertEqual(pinned.offerPhase(at: now), .fat)
    }

    func testOpenEatingWindowIsNeutralGreen() {
        let eating = state(TimerState(eatingStartTimestamp: now - 3600, isEating: true))
        XCTAssertEqual(eating.offerPhase(at: now), .fat)
    }

    func testClosedEatingWindowIsNeutralGreen() {
        let over = state(TimerState(eatingStartTimestamp: now - 9 * 3600, isEating: true))
        XCTAssertEqual(over.offerPhase(at: now), .fat)
    }

    func testLapsedEatingWindowReadsLikeIdle() {
        let lapsed = state(TimerState(eatingStartTimestamp: now - 40 * 3600, isEating: true))
        XCTAssertEqual(lapsed.offerPhase(at: now), .fed)
    }

    func testResultScreenTakesThePhaseOfTheStagedTime() {
        let complete = state(TimerState(stagedElapsed: 10 * 3600))
        XCTAssertEqual(complete.offerPhase(at: now), .fat)
    }
}
