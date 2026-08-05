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

        dispatch(AppLifecycleAction.lastMealLogged(backdated: !meal.isFresh, minutesAgo: minutesAgo))
        // Confirming from the window-closed screen chains the next fast.
        let timer = app.timerState
        let eatingEnd = timer.eatingEndTimestamp(plan: app.activePlan)
        if timer.isEating && Clock.now().timeIntervalSince1970 >= eatingEnd {
            dispatch(AppLifecycleAction.fastChained)
        }
        dispatch(TimerAction.started(startTimestamp: fastStart,
                                     goalHours: app.planState.plan.fastHours))
        dispatch(UIAction.mealPickerClosed)
    }
}
