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

        let fastStart: Double
        if meal.isFresh {
            // The seed hasn't landed yet — fall back to the window close moment.
            fastStart = app.timerState.eatingEndTimestamp(plan: app.activePlan)
        } else {
            let minutesAgo = MealMath.minutesAgo(
                ateDay: meal.ateDay,
                ateMin: meal.ateMin,
                nowMinuteOfDay: Clock.minuteOfDay()
            )
            fastStart = Clock.now().timeIntervalSince1970 - Double(minutesAgo) * 60
        }

        dispatch(AppLifecycleAction.fastChained)
        // A new fast: its goal is the plan as it stands now, not the one the window
        // it chains from was measured with.
        dispatch(TimerAction.started(startTimestamp: fastStart,
                                     goalHours: app.planState.plan.fastHours))
    }
}
