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

        let minutesAgo = MealMath.minutesAgo(
            ateDay: meal.ateDay,
            ateMin: meal.ateMin,
            nowMinuteOfDay: Clock.minuteOfDay()
        )
        let fastStart = Clock.now().timeIntervalSince1970 - Double(minutesAgo) * 60

        // `backdated` is read off the distance, not off `isFresh`. The flag used to
        // say "the picker has a value", which after the sheet seeded itself on open
        // was always true — so the analytics could not tell a real back-date from
        // someone opening the sheet and confirming straight away.
        dispatch(AppLifecycleAction.lastMealLogged(backdated: minutesAgo > 0, minutesAgo: minutesAgo))
        // Confirming from the window-closed screen chains the next fast.
        let timer = app.timerState
        let eatingEnd = timer.eatingEndTimestamp(fastHours: app.planState.plan.fastHours)
        if timer.isEating && Clock.now().timeIntervalSince1970 >= eatingEnd {
            dispatch(AppLifecycleAction.fastChained)
        }
        dispatch(TimerAction.started(startTimestamp: fastStart))
        dispatch(UIAction.mealPickerClosed)
    }
}
