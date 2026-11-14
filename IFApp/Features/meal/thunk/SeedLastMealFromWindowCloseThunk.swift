//
//  SeedLastMealFromWindowCloseThunk.swift
//  IFApp
//

import Foundation
import Redux

struct SeedLastMealFromWindowCloseThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState, app.mealState.isFresh else { return }
        let close = app.timerState.eatingEndTimestamp(plan: app.activePlan)
        let mins = MealMath.minutesAgo(of: Date(timeIntervalSince1970: close), now: Clock.now())
        dispatch(MealAction.initialized(minutesAgo: mins))
    }
}
