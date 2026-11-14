//
//  CompleteStatePersistenceTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class CompleteStatePersistenceTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "CompleteStatePersistenceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func save(_ timer: TimerState, to repo: TimerPersistenceRepository) {
        repo.save(fastStartTimestamp: timer.fastStartTimestamp,
                  goalHours: timer.goalHours,
                  isRunning: timer.isRunning,
                  completedSessions: timer.completedSessionsCount,
                  hasCelebrated: timer.hasCelebrated,
                  eatingStartTimestamp: timer.eatingStartTimestamp,
                  isEating: timer.isEating,
                  stagedElapsed: timer.stagedElapsed,
                  fastEndTimestamp: timer.fastEndTimestamp,
                  streakCount: timer.streakCount,
                  lastGoalDate: timer.lastGoalDate,
                  freezeSpentMonth: timer.freezeSpentMonth)
    }

    private func running(start: Double = 1_000_000) -> TimerState {
        TimerState(fastStartTimestamp: start, goalHours: 16, isRunning: true)
    }

    // MARK: - Repository

    func testEndedFastRoundTripsThroughDefaults() {
        let repo = TimerPersistenceRepository(defaults: defaults)
        let ended = timerReducer(state: running(),
                                 action: TimerAction.stopped(elapsed: 58_000,
                                                             qualifiesAsCompleted: true,
                                                             backdatedMinutes: 0))
        save(ended, to: repo)

        let loaded = TimerPersistenceRepository(defaults: defaults).load()
        XCTAssertFalse(loaded.isRunning)
        XCTAssertEqual(loaded.stagedElapsed, 58_000)
        XCTAssertEqual(loaded.fastEndTimestamp, 1_058_000)
    }

    func testMissingKeysReadAsNothingEnded() {
        defaults.set(false, forKey: "is_running")
        let loaded = TimerPersistenceRepository(defaults: defaults).load()
        XCTAssertEqual(loaded.stagedElapsed, 0)
        XCTAssertEqual(loaded.fastEndTimestamp, 0)
    }

    // MARK: - Reducer — every way off the result screen clears what was persisted

    private var complete: TimerState {
        timerReducer(state: running(),
                     action: TimerAction.stopped(elapsed: 7_200, qualifiesAsCompleted: false,
                                                 backdatedMinutes: 0))
    }

    func testOpeningTheEatingWindowClearsTheEndedFast() {
        let eating = timerReducer(state: complete,
                                  action: TimerAction.eatingStarted(startTimestamp: 1_007_200))
        XCTAssertEqual(eating.stagedElapsed, 0)
        XCTAssertEqual(eating.fastEndTimestamp, 0)
    }

    func testResetClearsTheEndedFast() {
        let idle = timerReducer(state: complete, action: TimerAction.reset(elapsed: 7_200))
        XCTAssertEqual(idle.stagedElapsed, 0)
        XCTAssertEqual(idle.fastEndTimestamp, 0)
    }

    func testUndoingTheEndingClearsTheEndedFast() {
        let resumed = timerReducer(state: complete,
                                   action: TimerAction.stopUndone(startTimestamp: 1_000_000))
        XCTAssertEqual(resumed.stagedElapsed, 0)
        XCTAssertEqual(resumed.fastEndTimestamp, 0)
    }

    func testResetPersistedOverAnEndingRelaunchesIdle() {
        let repo = TimerPersistenceRepository(defaults: defaults)
        save(complete, to: repo)
        save(timerReducer(state: complete, action: TimerAction.reset(elapsed: 7_200)), to: repo)

        let loaded = repo.load()
        XCTAssertEqual(loaded.stagedElapsed, 0)
        XCTAssertEqual(loaded.fastEndTimestamp, 0)
    }

    // MARK: - How long a restored result screen is held

    private func restored(end: Double = 2_000_000) -> TimerState {
        TimerState(fastStartTimestamp: 0, goalHours: 16, isRunning: false,
                   stagedElapsed: 57_600, fastEndTimestamp: end, hasCelebrated: true)
    }

    private let plan = Plan(hours: 16)
    private let horizon = 8.0 * 3600 + 24 * 3600

    func testResultScreenIsHeldJustBeforeTheHorizon() {
        let state = restored()
        let kept = state.droppingLapsedEnding(at: 2_000_000 + horizon - 1, plan: plan)
        XCTAssertEqual(kept, state)
    }

    func testResultScreenFallsToIdleAtTheHorizon() {
        let idle = restored().droppingLapsedEnding(at: 2_000_000 + horizon, plan: plan)
        XCTAssertEqual(idle.stagedElapsed, 0)
        XCTAssertEqual(idle.fastEndTimestamp, 0)
        XCTAssertEqual(idle.goalHours, 0)
        XCTAssertFalse(idle.hasCelebrated)
        XCTAssertFalse(idle.isRunning)
        XCTAssertFalse(idle.isEating)
    }

    func testHorizonFollowsThePlansWindow() {
        let state = restored()
        let at = 2_000_000 + 6.0 * 3600 + 24 * 3600
        XCTAssertEqual(state.droppingLapsedEnding(at: at - 1, plan: Plan(hours: 18)), state)
        XCTAssertEqual(state.droppingLapsedEnding(at: at, plan: Plan(hours: 18)).stagedElapsed, 0)
    }

    func testOnlyTheResultScreenIsAged() {
        let far = 9_999_999_999.0
        var fast = running()
        fast.stagedElapsed = 600
        XCTAssertEqual(fast.droppingLapsedEnding(at: far, plan: plan), fast)
        let eating = TimerState(goalHours: 16, eatingStartTimestamp: 1_000_000, isEating: true)
        XCTAssertEqual(eating.droppingLapsedEnding(at: far, plan: plan), eating)
    }

    func testEndingWithoutAnAnchorIsCleared() {
        var state = restored()
        state.fastEndTimestamp = 0
        XCTAssertEqual(state.droppingLapsedEnding(at: 0, plan: plan).stagedElapsed, 0)
    }

    func testClosedWindowHorizonBoundary() {
        XCTAssertFalse(TimerState.closedWindowHasLapsed(closedAt: 100, now: 100 + 24 * 3600 - 1))
        XCTAssertTrue(TimerState.closedWindowHasLapsed(closedAt: 100, now: 100 + 24 * 3600))
    }

    func testLapsedEndingLandsOnTheSameIdleAsReset() {
        var state = restored()
        state.eatingStartTimestamp = 1_234
        state.streakCount = 5
        state.completedSessionsCount = 7
        let dropped = state.droppingLapsedEnding(at: 9_999_999_999, plan: plan)
        let reset = timerReducer(state: state, action: TimerAction.reset(elapsed: 57_600))
        XCTAssertEqual(dropped, reset)
        XCTAssertEqual(dropped, state.withoutCycle())
        XCTAssertEqual(dropped.eatingStartTimestamp, 0)
        XCTAssertEqual(dropped.streakCount, 5)
        XCTAssertEqual(dropped.completedSessionsCount, 7)
    }
}
