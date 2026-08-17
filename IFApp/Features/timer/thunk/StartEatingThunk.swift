//
//  StartEatingThunk.swift
//  IFApp
//
//  Opens the eating window from the complete screen: reads the clock (a side effect)
//  and dispatches a pure `.eatingStarted`. Window length is derived from the plan.
//

import Foundation
import Redux

struct StartEatingThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let now = Date().timeIntervalSince1970
        // The window is anchored to the meal, not to the tap. Someone who sat on the
        // result screen for an hour — or who back-dated the ending by two — opens a
        // window that closes on time rather than one that runs long and drags the
        // whole chain after it. The tap stands in only when there is no confirmed
        // ending to anchor to, which is state written before this shipped.
        let anchor = (state as? AppState).map { $0.timerState.fastEndTimestamp } ?? 0
        dispatch(TimerAction.eatingStarted(startTimestamp: anchor > 0 ? anchor : now))
        dispatch(MealAction.cleared)
    }
}
