//
//  MealMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class MealMiddlewareTests: XCTestCase {
    private final class Box {
        var actions: [Action] = []
        var thunks: [Thunk] = []
    }

    private func onlyThunk(_ action: Action, file: StaticString = #filePath, line: UInt = #line) -> Thunk? {
        let box = Box()
        let dispatch = DispatchFunction(dispatchAction: { box.actions.append($0) },
                                        dispatchThunk: { box.thunks.append($0) })
        MealMiddleware().handle(action: action, state: AppState(), dispatch: dispatch)
        XCTAssertEqual(box.thunks.count, 1, "\(action)", file: file, line: line)
        XCTAssertTrue(box.actions.isEmpty, "\(action)", file: file, line: line)
        return box.thunks.first
    }

    func testChipTapPicksThatChip() throws {
        let thunk = try XCTUnwrap(onlyThunk(MealAction.chipTapped(.threeHours)) as? PickMealChipThunk)
        XCTAssertEqual(thunk.chip, .threeHours)
    }

    func testScrubFeedbackPlaysThatFeedback() throws {
        let thunk = try XCTUnwrap(onlyThunk(MealAction.scrubFeedbackRequested(.edge)) as? MealFeedbackThunk)
        XCTAssertEqual(thunk.kind, .edge)
    }

    func testExactTimeSetsThatTime() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let thunk = try XCTUnwrap(onlyThunk(MealAction.exactTimeChosen(date)) as? SetExactMealTimeThunk)
        XCTAssertEqual(thunk.date, date)
    }

    func testConfirmTapLogsTheMeal() {
        XCTAssertTrue(onlyThunk(MealAction.confirmTapped) is ConfirmLastMealThunk)
    }

    func testClosedWindowSeedsTheMeal() {
        XCTAssertTrue(onlyThunk(MealAction.windowClosedShown) is SeedLastMealFromWindowCloseThunk)
    }

    func testFactsRunNothing() {
        let actions: [Action] = [MealAction.chipPicked(idx: 1, minutesAgo: 60),
                                 MealAction.scrubbed(minutesAgo: 30),
                                 MealAction.exactTimePicked(minutesAgo: 90),
                                 MealAction.initialized(minutesAgo: 10),
                                 MealAction.cleared, MealAction.pickerConfirmed]
        for action in actions {
            let box = Box()
            MealMiddleware().handle(action: action, state: AppState(),
                                    dispatch: DispatchFunction(dispatchAction: { box.actions.append($0) },
                                                               dispatchThunk: { box.thunks.append($0) }))
            XCTAssertTrue(box.thunks.isEmpty, "\(action)")
            XCTAssertTrue(box.actions.isEmpty, "\(action)")
        }
    }
}
