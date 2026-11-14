//
//  ContinueFastingThunk.swift
//  IFApp
//

import Foundation
import Redux

struct ContinueFastingThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let meal = app.mealState

        let now = Clock.now()
        let minutesAgo: Int
        if meal.isFresh {
            let close = app.timerState.eatingEndTimestamp(plan: app.activePlan)
            minutesAgo = MealMath.minutesAgo(of: Date(timeIntervalSince1970: close), now: now)
        } else {
            minutesAgo = meal.minutesAgo
        }
        let fastStart = MealMath.fastStart(minutesAgo: minutesAgo, now: now.timeIntervalSince1970)

        dispatch(AppLifecycleAction.fastChained)
        dispatch(TimerAction.started(startTimestamp: fastStart,
                                     goalHours: app.planState.plan.fastHours))
    }
}
