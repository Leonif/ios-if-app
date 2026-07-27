//
//  ContinueFastingThunk.swift
//  IFApp
//
//  Chains the next fast from the window-closed screen: starts from the Last-meal
//  control's time (seeded to the window close by default). Reads the clock (a side
//  effect) and dispatches a pure `.started` — which also closes the eating window.
//

import Foundation
import Redux

struct ContinueFastingThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let meal = app.mealState

        let now = Clock.now().timeIntervalSince1970
        let unclamped: Double
        if meal.isFresh {
            // The seed hasn't landed yet — fall back to the window close moment.
            unclamped = app.timerState.eatingEndTimestamp(fastHours: app.planState.plan.fastHours)
        } else {
            // `MealMath.minutesAgo` is where the "never in the future" clamp lives, so
            // this path and `ConfirmLastMealThunk` are guarded by the same code rather
            // than by two guards that can drift apart.
            let minutesAgo = MealMath.minutesAgo(
                ateDay: meal.ateDay,
                ateMin: meal.ateMin,
                nowMinuteOfDay: Clock.minuteOfDay()
            )
            unclamped = now - Double(minutesAgo) * 60
        }
        // The fallback above is a stored timestamp, not a picker value, so it gets the
        // same floor: a fast never starts after the moment it is started.
        let fastStart = min(unclamped, now)

        dispatch(AppLifecycleAction.fastChained)
        dispatch(TimerAction.started(startTimestamp: fastStart))
    }
}
