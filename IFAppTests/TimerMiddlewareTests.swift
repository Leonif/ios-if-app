//
//  TimerMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class TimerMiddlewareTests: XCTestCase {
    private final class Box {
        var actions: [Action] = []
        var thunks: [Thunk] = []
    }

    private func handled(_ action: Action) -> Box {
        let box = Box()
        let dispatch = DispatchFunction(dispatchAction: { box.actions.append($0) },
                                        dispatchThunk: { box.thunks.append($0) })
        TimerMiddleware().handle(action: action, state: AppState(), dispatch: dispatch)
        return box
    }

    private func assertRuns<T: Thunk>(_ intent: TimerAction, _ type: T.Type,
                                      file: StaticString = #filePath, line: UInt = #line) {
        let box = handled(intent)
        XCTAssertEqual(box.thunks.count, 1, file: file, line: line)
        XCTAssertTrue(box.thunks.first is T, "\(intent)", file: file, line: line)
        XCTAssertTrue(box.actions.isEmpty, file: file, line: line)
    }

    func testStartFastTapStartsTheFast() {
        assertRuns(.startFastTapped, StartFastThunk.self)
    }

    func testResumeTapResumesTheFast() {
        assertRuns(.resumeTapped, ResumeFastThunk.self)
    }

    func testResetTapResetsTheFast() {
        assertRuns(.resetTapped, ResetFastThunk.self)
    }

    func testStartEatingTapOpensTheWindow() {
        assertRuns(.startEatingTapped, StartEatingThunk.self)
    }

    func testContinueFastingTapChainsTheNextFast() {
        assertRuns(.continueFastingTapped, ContinueFastingThunk.self)
    }

    func testGoalMomentCelebratesTheGoal() {
        assertRuns(.goalMomentStarted, CelebrateGoalThunk.self)
    }

    func testOtherTimerActionsRunNothing() {
        let actions: [Action] = [TimerAction.started(startTimestamp: 1, goalHours: 16),
                                 TimerAction.reset(elapsed: 60),
                                 TimerAction.eatingEnded,
                                 AppLifecycleAction.appOpened]
        for action in actions {
            let box = handled(action)
            XCTAssertTrue(box.thunks.isEmpty, "\(action)")
            XCTAssertTrue(box.actions.isEmpty, "\(action)")
        }
    }
}
