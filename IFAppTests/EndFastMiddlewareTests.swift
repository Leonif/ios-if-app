//
//  EndFastMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class EndFastMiddlewareTests: XCTestCase {
    private final class Box {
        var actions: [Action] = []
        var thunks: [Thunk] = []
    }

    private func handled(_ action: Action) -> Box {
        let box = Box()
        EndFastMiddleware().handle(action: action, state: AppState(),
                                   dispatch: DispatchFunction(dispatchAction: { box.actions.append($0) },
                                                              dispatchThunk: { box.thunks.append($0) }))
        return box
    }

    private func onlyThunk(_ action: Action, file: StaticString = #filePath, line: UInt = #line) -> Thunk? {
        let box = handled(action)
        XCTAssertEqual(box.thunks.count, 1, "\(action)", file: file, line: line)
        XCTAssertTrue(box.actions.isEmpty, "\(action)", file: file, line: line)
        return box.thunks.first
    }

    func testEndFastTapOpensTheSheet() {
        XCTAssertTrue(onlyThunk(EndFastAction.openTapped) is OpenEndFastThunk)
    }

    func testChipTapPicksThatOffset() throws {
        let thunk = try XCTUnwrap(onlyThunk(EndFastAction.chipTapped(.daysBack(1))) as? EndFastChipThunk)
        XCTAssertEqual(thunk.offset, .daysBack(1))
    }

    func testStepTapStepsByThoseMinutes() throws {
        let thunk = try XCTUnwrap(onlyThunk(EndFastAction.stepTapped(minutes: -15)) as? EndFastStepThunk)
        XCTAssertEqual(thunk.minutes, -15)
    }

    func testConfirmTapEndsTheFast() {
        XCTAssertTrue(onlyThunk(EndFastAction.confirmTapped) is ConfirmEndFastThunk)
    }

    func testFactsRunNothing() {
        let actions: [Action] = [EndFastAction.chipPicked(timestamp: 1, latest: 2),
                                 EndFastAction.timeStepped(byMinutes: 5, latest: 2),
                                 EndFastAction.refusalWithdrawn, EndFastAction.closed]
        for action in actions {
            let box = handled(action)
            XCTAssertTrue(box.thunks.isEmpty, "\(action)")
            XCTAssertTrue(box.actions.isEmpty, "\(action)")
        }
    }
}
