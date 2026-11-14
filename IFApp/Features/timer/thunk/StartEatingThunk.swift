//
//  StartEatingThunk.swift
//  IFApp
//

import Foundation
import Redux

struct StartEatingThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let now = Date().timeIntervalSince1970
        let anchor = (state as? AppState).map { $0.timerState.fastEndTimestamp } ?? 0
        dispatch(TimerAction.eatingStarted(startTimestamp: anchor > 0 ? anchor : now))
        dispatch(MealAction.cleared)
    }
}
