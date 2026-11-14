//
//  TimerElapsedTests.swift
//  IFAppTests
//

import XCTest
@testable import IFApp

final class TimerElapsedTests: XCTestCase {

    private let now: Double = 1_800_000_000
    private let plan = Plan(hours: 16)

    // MARK: - elapsed(at:)

    func testRunningFastCountsFromItsStart() {
        let timer = TimerState(fastStartTimestamp: now - 5 * 3600, isRunning: true, stagedElapsed: 999)
        XCTAssertEqual(timer.elapsed(at: now), 5 * 3600)
    }

    func testRunningFastStartedInTheFutureReadsZero() {
        let timer = TimerState(fastStartTimestamp: now + 60, isRunning: true)
        XCTAssertEqual(timer.elapsed(at: now), 0)
    }

    func testStoppedTimerReadsTheStagedValue() {
        let timer = TimerState(fastStartTimestamp: now - 5 * 3600, isRunning: false, stagedElapsed: 7200)
        XCTAssertEqual(timer.elapsed(at: now), 7200)
    }

    func testIdleTimerReadsZero() {
        XCTAssertEqual(TimerState().elapsed(at: now), 0)
    }

    // MARK: - Eating window

    func testEatingRemainingAndOverElapsedAreTwoSidesOfTheClose() {
        let open = TimerState(eatingStartTimestamp: now - 3600, isEating: true)
        XCTAssertEqual(open.eatingRemaining(at: now, plan: plan), 7 * 3600)
        XCTAssertEqual(open.eatingOverElapsed(at: now, plan: plan), 0)

        let closed = TimerState(eatingStartTimestamp: now - 9 * 3600, isEating: true)
        XCTAssertEqual(closed.eatingRemaining(at: now, plan: plan), 0)
        XCTAssertEqual(closed.eatingOverElapsed(at: now, plan: plan), 3600)
    }

    // MARK: - screenState(at:plan:)

    func testScreenStates() {
        XCTAssertEqual(TimerState().screenState(at: now, plan: plan), .idle)
        XCTAssertEqual(TimerState(stagedElapsed: 60).screenState(at: now, plan: plan), .complete)
        XCTAssertEqual(TimerState(fastStartTimestamp: now - 3600, isRunning: true)
            .screenState(at: now, plan: plan), .active)
        XCTAssertEqual(TimerState(fastStartTimestamp: now - 16 * 3600, isRunning: true)
            .screenState(at: now, plan: plan), .goalReached)
        XCTAssertEqual(TimerState(eatingStartTimestamp: now - 3600, isEating: true)
            .screenState(at: now, plan: plan), .eating)
        XCTAssertEqual(TimerState(eatingStartTimestamp: now - 9 * 3600, isEating: true)
            .screenState(at: now, plan: plan), .eatingOver)
    }

    func testClosedWindowFallsToIdleAtTheHorizon() {
        let closedAt = now - TimerState.closedWindowHorizon
        let timer = TimerState(eatingStartTimestamp: closedAt - 8 * 3600, isEating: true)
        XCTAssertEqual(timer.screenState(at: now, plan: plan), .idle)
        XCTAssertEqual(timer.screenState(at: now - 1, plan: plan), .eatingOver)
    }

    func testGoalReachedFollowsThePlanPassedIn() {
        let timer = TimerState(fastStartTimestamp: now - 17 * 3600, isRunning: true)
        XCTAssertEqual(timer.screenState(at: now, plan: Plan(hours: 16)), .goalReached)
        XCTAssertEqual(timer.screenState(at: now, plan: Plan(hours: 18)), .active)
    }
}
