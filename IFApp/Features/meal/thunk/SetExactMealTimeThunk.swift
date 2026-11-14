//
//  SetExactMealTimeThunk.swift
//  IFApp
//

import Foundation
import Redux

struct SetExactMealTimeThunk: Thunk {
    let date: Date

    init(_ date: Date) { self.date = date }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let now = Clock.now()
        let mins = MealMath.minutesAgo(of: date, now: now)
        guard mins > 0 else {
            dispatch(MealAction.cleared)
            return
        }
        dispatch(MealAction.exactTimePicked(minutesAgo: mins))
    }
}
