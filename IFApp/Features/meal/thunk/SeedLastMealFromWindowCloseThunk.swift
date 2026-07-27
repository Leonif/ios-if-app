//
//  SeedLastMealFromWindowCloseThunk.swift
//  IFApp
//
//  Seeds the Last-meal control to the moment the eating window closed, so
//  "Continue fasting" backdates from there by default. The close moment and "now"
//  are resolved here rather than in the view, so the day offset is measured when the
//  seed is dispatched instead of whenever the screen happened to redraw.
//

import Foundation
import Redux

struct SeedLastMealFromWindowCloseThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState, app.mealState.isFresh else { return }
        let close = app.timerState.eatingEndTimestamp(fastHours: app.planState.plan.fastHours)
        let now = Clock.now()
        // Measured as a distance rather than as a calendar day offset, so a window
        // that closed further back than the ribbon reaches clamps to the 7-day limit
        // instead of landing on a plausible-looking wrong time of day.
        let mins = MealMath.minutesAgo(of: Date(timeIntervalSince1970: close), now: now)
        let moment = MealMath.moment(minutesAgo: mins, nowMinuteOfDay: Clock.minuteOfDay(now))
        dispatch(MealAction.initialized(ateDay: moment.ateDay, ateMin: moment.ateMin))
    }
}
