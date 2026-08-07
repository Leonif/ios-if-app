//
//  ResumeFastTests.swift
//  IFAppTests
//
//  TF-3: undoing "End fast" from the result screen. The one thing the acceptance
//  criteria single out is that the undo restores the goal *this fast* was pinned to,
//  not the plan as it stands now — reusing `StartFastThunk` would have compiled and
//  quietly rewritten it, so the test seeds a plan that disagrees with the pinned goal
//  and would catch exactly that.
//

import XCTest
import Redux
@testable import IFApp

final class ResumeFastTests: XCTestCase {

    /// A finished fast waiting on the result screen: two hours staged, pinned to an
    /// 18h goal, while the plan the user has *selected* is 16h.
    private func completeState(stagedElapsed: TimeInterval = 7200,
                               pinnedGoalHours: Double = 18,
                               planHours: Int = 16,
                               records: [FastRecord] = []) -> AppState {
        var state = AppState()
        state.timerState = TimerState(
            fastStartTimestamp: 0,
            goalHours: pinnedGoalHours,
            isRunning: false,
            stagedElapsed: stagedElapsed,
            completedSessionsCount: 4,
            hasCelebrated: true,
            streakCount: 3,
            lastGoalDate: "2026-08-06"
        )
        state.planState = PlanState(plan: Plan(hours: planHours))
        state.historyState = HistoryState(records: records)
        return state
    }

    private func record(duration: TimeInterval, goalHours: Double = 18) -> FastRecord {
        let start = Date().timeIntervalSince1970 - duration
        return FastRecord(id: UUID(),
                          startTimestamp: start,
                          endTimestamp: start + duration,
                          goalHours: goalHours,
                          planLabel: Plan(goalHours: goalHours).ratioLabel)
    }

    private func dispatched(from state: AppState) async -> [Action] {
        let box = Box()
        await ResumeFastThunk().execute(state: state) { box.actions.append($0) }
        return box.actions
    }

    private final class Box { var actions: [Action] = [] }

    // MARK: The pinned goal

    /// The acceptance criterion, at the reducer: undo puts the fast back without
    /// touching the goal it runs to. `.started` would have overwritten it.
    func testUndoKeepsThePinnedGoal() {
        let before = completeState().timerState
        let after = timerReducer(state: before,
                                 action: TimerAction.stopUndone(startTimestamp: 1_000))

        XCTAssertEqual(after.goalHours, 18, "the goal belongs to this fast, not to the plan")
        XCTAssertTrue(after.isRunning)
        XCTAssertEqual(after.fastStartTimestamp, 1_000)
        XCTAssertEqual(after.stagedElapsed, 0)
    }

    /// Reaching the goal is what counts a session and moves the streak; ending a fast
    /// is not, so undoing an ending must leave all three alone. `hasCelebrated` is in
    /// the list because clearing it would replay the goal moment on a resumed overtime
    /// fast, and the replay is what would double-count the other two.
    func testUndoDoesNotTouchStreakOrCompletionCounters() {
        let before = completeState().timerState
        let after = timerReducer(state: before,
                                 action: TimerAction.stopUndone(startTimestamp: 1_000))

        XCTAssertEqual(after.completedSessionsCount, before.completedSessionsCount)
        XCTAssertEqual(after.streakCount, before.streakCount)
        XCTAssertEqual(after.lastGoalDate, before.lastGoalDate)
        XCTAssertTrue(after.hasCelebrated, "a resumed overtime fast must not celebrate twice")
    }

    // MARK: The shared start rule

    /// Where a fast put in flight has its start is one definition, used by both the
    /// start path and the undo. Asserted on `TimerState` rather than through either
    /// caller, because the point of the rule living there is that neither caller owns
    /// it (invariant 8).
    func testStartTimestampCarriesTheStagedElapsed() {
        let staged = completeState(stagedElapsed: 7200).timerState

        XCTAssertEqual(staged.startTimestamp(at: 1_000_000), 1_000_000 - 7200)

        var fresh = staged
        fresh.stagedElapsed = 0
        XCTAssertEqual(fresh.startTimestamp(at: 1_000_000), 1_000_000,
                       "nothing staged means the fast starts now")
    }

    // MARK: The thunk

    /// It dispatches the undo, and specifically not a start — the distinction the
    /// whole thunk exists for.
    func testThunkDispatchesUndoAndNeverStart() async {
        let actions = await dispatched(from: completeState())

        XCTAssertFalse(actions.contains { if case .started = ($0 as? TimerAction) { return true }; return false },
                       "TF-3: a start would re-pin the goal from the current plan")
        guard case let .stopUndone(startTimestamp)? = actions.compactMap({ $0 as? TimerAction }).first else {
            return XCTFail("expected a .stopUndone")
        }
        // The count picks up where it left off rather than restarting from zero.
        let elapsedAfterResume = Date().timeIntervalSince1970 - startTimestamp
        XCTAssertEqual(elapsedAfterResume, 7200, accuracy: 2)
    }

    /// The record written by the ending goes with it.
    func testThunkDeletesTheRecordTheEndingWrote() async {
        let justWritten = record(duration: 7200)
        let older = record(duration: 16 * 3600)
        let actions = await dispatched(from: completeState(records: [justWritten, older]))

        let deleted = actions.compactMap { action -> UUID? in
            if case let .deleted(id)? = action as? HistoryAction { return id }
            return nil
        }
        XCTAssertEqual(deleted, [justWritten.id])
    }

    /// A fast too short to be written (under `HistoryMiddleware.minimumDuration`) still
    /// reaches the result screen. Deleting "the newest record" there would throw away
    /// the user's *previous* fast, so nothing is deleted.
    func testThunkDeletesNothingWhenTheEndingWroteNoRecord() async {
        let older = record(duration: 16 * 3600)
        let actions = await dispatched(from: completeState(stagedElapsed: 30, records: [older]))

        XCTAssertFalse(actions.contains { $0 is HistoryAction },
                       "no record was written for a 30-second fast, so none may be deleted")
    }

    /// Nothing to undo while a fast is running: the action does not exist in `.active`,
    /// and a stray dispatch must not restart the clock.
    func testThunkIsInertWhileAFastIsRunning() async {
        var state = completeState()
        state.timerState.isRunning = true
        state.timerState.stagedElapsed = 0

        let actions = await dispatched(from: state)

        XCTAssertTrue(actions.isEmpty)
    }
}
