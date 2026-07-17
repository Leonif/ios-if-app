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
        dispatch(TimerAction.eatingStarted(startTimestamp: now))
        dispatch(MealAction.cleared)
    }
}
