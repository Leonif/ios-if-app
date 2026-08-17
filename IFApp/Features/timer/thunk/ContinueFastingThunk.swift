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

        let now = Clock.now()
        // Both branches end in one distance, and the distance is turned into a start
        // by one function — so the "never in the future" floor cannot be present on
        // one path and missing on the other, which is how these two drifted apart the
        // last time the arithmetic was written out twice.
        let minutesAgo: Int
        if meal.isFresh {
            // Nothing chosen — fall back to the moment the eating window closed.
            let close = app.timerState.eatingEndTimestamp(plan: app.activePlan)
            minutesAgo = MealMath.minutesAgo(of: Date(timeIntervalSince1970: close), now: now)
        } else {
            minutesAgo = meal.minutesAgo
        }
        let fastStart = MealMath.fastStart(minutesAgo: minutesAgo, now: now.timeIntervalSince1970)

        dispatch(AppLifecycleAction.fastChained)
        // A new fast: its goal is the plan as it stands now, not the one the window
        // it chains from was measured with.
        dispatch(TimerAction.started(startTimestamp: fastStart,
                                     goalHours: app.planState.plan.fastHours))
    }
}
