//
//  ConfirmLastMealThunk.swift
//  IFApp
//
//  Confirms the picker: back-dates the fast start to the logged meal time
//  (or now, if fresh) and starts the timer, then closes the sheet.
//

import Foundation
import Redux

struct ConfirmLastMealThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let meal = app.mealState

        let now = Clock.now().timeIntervalSince1970
        let minutesAgo = meal.minutesAgo
        // Resolved here and only here: the distance the user chose becomes a moment
        // against the clock of the instant the fast actually starts.
        let fastStart = MealMath.fastStart(minutesAgo: minutesAgo, now: now)

        // `backdated` is read off the distance, not off "the picker has a value".
        // The sheet no longer seeds itself on open, so the flag can finally tell a
        // real back-date from someone opening the sheet and confirming straight away
        // — which is what kept it out of GA4 until now.
        dispatch(AppLifecycleAction.lastMealLogged(backdated: minutesAgo > 0,
                                                   minutesAgo: minutesAgo,
                                                   inputMethod: meal.inputMethod.rawValue))
        // Confirming from the window-closed screen chains the next fast.
        let timer = app.timerState
        let eatingEnd = timer.eatingEndTimestamp(plan: app.activePlan)
        if timer.isEating && now >= eatingEnd {
            dispatch(AppLifecycleAction.fastChained)
        }
        dispatch(TimerAction.started(startTimestamp: fastStart,
                                     goalHours: app.planState.plan.fastHours))
        dispatch(UIAction.mealPickerClosed)
    }
}
