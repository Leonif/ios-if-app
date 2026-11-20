//
//  MealMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class MealMiddleware: Middleware {
    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        switch action {
        case let MealAction.chipTapped(chip):
            dispatch(PickMealChipThunk(chip))
        case let MealAction.scrubFeedbackRequested(kind):
            dispatch(MealFeedbackThunk(kind))
        case let MealAction.exactTimeChosen(date):
            dispatch(SetExactMealTimeThunk(date))
        case MealAction.confirmTapped:
            dispatch(ConfirmLastMealThunk())
        case MealAction.windowClosedShown:
            dispatch(SeedLastMealFromWindowCloseThunk())
        default:
            break
        }
    }
}
