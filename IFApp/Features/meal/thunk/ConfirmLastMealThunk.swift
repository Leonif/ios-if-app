//
//  ConfirmLastMealThunk.swift
//  IFApp
//

import Foundation
import Redux

struct ConfirmLastMealThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let meal = app.mealState

        let now = Clock.now().timeIntervalSince1970
        let minutesAgo = meal.minutesAgo
        let fastStart = MealMath.fastStart(minutesAgo: minutesAgo, now: now)

        dispatch(AppLifecycleAction.lastMealLogged(backdated: minutesAgo > 0,
                                                   minutesAgo: minutesAgo,
                                                   inputMethod: meal.inputMethod.rawValue))
        let timer = app.timerState
        let eatingEnd = timer.eatingEndTimestamp(plan: app.activePlan)
        if timer.isEating && now >= eatingEnd {
            dispatch(AppLifecycleAction.fastChained)
        }
        dispatch(TimerAction.started(startTimestamp: fastStart,
                                     goalHours: app.planState.plan.fastHours))
        dispatch(MealAction.pickerConfirmed)
        dispatch(UIAction.mealPickerClosed)
    }
}
