//
//  CompleteStatePersistenceTests.swift
//  IFAppTests
//
//  Queue card 24: the result screen ("complete" — fast ended, eating window not yet
//  opened) has to survive iOS unloading the app on it. It is carried entirely by
//  `stagedElapsed` and `fastEndTimestamp`, which were never stored, so a cold start
//  there relaunched into idle and the eating window — and its closing push — never
//  came. These tests pin both halves: the repository keeps the two values, and the
//  reducer leaves them in exactly the states that should outlive a relaunch.
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

    /// A running 16h fast that started at `start`.
    private func running(start: Double = 1_000_000) -> TimerState {
        TimerState(fastStartTimestamp: start, goalHours: 16, isRunning: true)
    }

    // MARK: Repository

    /// The defect itself: end a fast, persist, reload — the result screen is still there.
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

    /// Installs from before 1.5.2 have neither key. Absent must read as "nothing
    /// ended", or an update would put every idle install on a result screen.
    func testMissingKeysReadAsNothingEnded() {
        defaults.set(false, forKey: "is_running")
        let loaded = TimerPersistenceRepository(defaults: defaults).load()
        XCTAssertEqual(loaded.stagedElapsed, 0)
        XCTAssertEqual(loaded.fastEndTimestamp, 0)
    }

    // MARK: Reducer — every way off the result screen clears what was persisted

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

    /// After a reset has been persisted over a result screen, the next launch is idle —
    /// the stored zeroes overwrite the stored ending rather than leaving it behind.
    func testResetPersistedOverAnEndingRelaunchesIdle() {
        let repo = TimerPersistenceRepository(defaults: defaults)
        save(complete, to: repo)
        save(timerReducer(state: complete, action: TimerAction.reset(elapsed: 7_200)), to: repo)

        let loaded = repo.load()
        XCTAssertEqual(loaded.stagedElapsed, 0)
        XCTAssertEqual(loaded.fastEndTimestamp, 0)
    }

    // MARK: How long a restored result screen is held

    /// A 16:8 fast confirmed to have ended at `end`: its window would close 8h later,
    /// and the result screen is held for 24h past that.
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

    /// At the horizon exactly it goes — the same `>=` the closed-window screen uses.
    func testResultScreenFallsToIdleAtTheHorizon() {
        let idle = restored().droppingLapsedEnding(at: 2_000_000 + horizon, plan: plan)
        XCTAssertEqual(idle.stagedElapsed, 0)
        XCTAssertEqual(idle.fastEndTimestamp, 0)
        XCTAssertEqual(idle.goalHours, 0)
        XCTAssertFalse(idle.hasCelebrated)
        XCTAssertFalse(idle.isRunning)
        XCTAssertFalse(idle.isEating)
    }

    /// The window length is the plan's: an 18:6 ending lapses two hours sooner.
    func testHorizonFollowsThePlansWindow() {
        let state = restored()
        let at = 2_000_000 + 6.0 * 3600 + 24 * 3600
        XCTAssertEqual(state.droppingLapsedEnding(at: at - 1, plan: Plan(hours: 18)), state)
        XCTAssertEqual(state.droppingLapsedEnding(at: at, plan: Plan(hours: 18)).stagedElapsed, 0)
    }

    /// Only the result screen is aged: a running fast and an open window are not
    /// touched however old their numbers look.
    func testOnlyTheResultScreenIsAged() {
        let far = 9_999_999_999.0
        var fast = running()
        fast.stagedElapsed = 600
        XCTAssertEqual(fast.droppingLapsedEnding(at: far, plan: plan), fast)
        let eating = TimerState(goalHours: 16, eatingStartTimestamp: 1_000_000, isEating: true)
        XCTAssertEqual(eating.droppingLapsedEnding(at: far, plan: plan), eating)
    }

    /// Ended with no confirmed moment: nothing to measure from, so it is not kept.
    func testEndingWithoutAnAnchorIsCleared() {
        var state = restored()
        state.fastEndTimestamp = 0
        XCTAssertEqual(state.droppingLapsedEnding(at: 0, plan: plan).stagedElapsed, 0)
    }

    /// The closed-window screen and the result screen share one horizon.
    func testClosedWindowHorizonBoundary() {
        XCTAssertFalse(TimerState.closedWindowHasLapsed(closedAt: 100, now: 100 + 24 * 3600 - 1))
        XCTAssertTrue(TimerState.closedWindowHasLapsed(closedAt: 100, now: 100 + 24 * 3600))
    }
}
