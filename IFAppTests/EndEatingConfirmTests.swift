//
//  EndEatingConfirmTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class EndEatingConfirmTests: XCTestCase {

    private var eating: AppState {
        var state = AppState()
        state.timerState = TimerState(goalHours: 16, eatingStartTimestamp: 1_000_000, isEating: true)
        return state
    }

    func testOpeningTheConfirmationEndsNothing() {
        let opened = rootReducer(state: eating, action: UIAction.endEatingConfirmOpened)
        XCTAssertTrue(opened.uiState.endEatingConfirmOpen)
        XCTAssertEqual(opened.timerState, eating.timerState)
    }

    func testKeepingItOpenOnlyClosesTheSheet() {
        let opened = rootReducer(state: eating, action: UIAction.endEatingConfirmOpened)
        let kept = rootReducer(state: opened, action: UIAction.endEatingConfirmClosed)
        XCTAssertFalse(kept.uiState.endEatingConfirmOpen)
        XCTAssertTrue(kept.timerState.isEating)
        XCTAssertEqual(kept.timerState.eatingStartTimestamp, 1_000_000)
    }

    func testConfirmingEndsTheWindowAndClosesTheSheet() {
        var state = rootReducer(state: eating, action: UIAction.endEatingConfirmOpened)
        state = rootReducer(state: state, action: TimerAction.eatingEnded)
        state = rootReducer(state: state, action: UIAction.endEatingConfirmClosed)
        XCTAssertFalse(state.timerState.isEating)
        XCTAssertFalse(state.uiState.endEatingConfirmOpen)
    }
}
