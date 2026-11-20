//
//  HistoryMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class HistoryMiddlewareTests: XCTestCase {
    private final class Box { var thunks: [Thunk] = [] }

    private func thunks(after action: Action) -> [Thunk] {
        let box = Box()
        HistoryMiddleware().handle(
            action: action, state: AppState(),
            dispatch: DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { box.thunks.append($0) }))
        return box.thunks
    }

    func testExportTapRunsTheExport() {
        let thunks = thunks(after: HistoryAction.exportTapped)
        XCTAssertEqual(thunks.count, 1)
        XCTAssertTrue(thunks.first is ExportHistoryThunk)
    }

    func testDeleteRunsTheDeleteThunkForThatRecord() {
        let id = UUID()
        let thunks = thunks(after: HistoryAction.deleted(id: id))
        XCTAssertEqual(thunks.count, 1)
        XCTAssertEqual((thunks.first as? DeleteFastRecordThunk)?.id, id)
    }

    func testEndingARunningFastRunsTheSaveThunk() {
        let box = Box()
        let middleware = HistoryMiddleware()
        let dispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { box.thunks.append($0) })
        var running = AppState()
        running.timerState.isRunning = true
        running.timerState.fastStartTimestamp = 1_000
        middleware.handle(action: TimerAction.reset(elapsed: 0), state: running, dispatch: dispatch)
        middleware.handle(action: TimerAction.stopped(elapsed: 3_600, qualifiesAsCompleted: true, backdatedMinutes: 0),
                          state: AppState(), dispatch: dispatch)
        let saved = box.thunks.compactMap { $0 as? SaveFastRecordThunk }
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.record.startTimestamp, 1_000)
        XCTAssertEqual(saved.first?.record.endTimestamp, 4_600)
    }

    func testTheExportsOwnActionsRunNothing() {
        for action in [HistoryAction.exportStarted, .exportFailed, .exportFinished(shared: true)] {
            XCTAssertTrue(thunks(after: action).isEmpty)
        }
    }
}
