//
//  OpenMealPickerThunk.swift
//  IFApp
//
//  Opens the picker, seeding the time to now if it hasn't been set yet.
//

import Redux

struct OpenMealPickerThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(MealAction.initializedToNow(minuteOfDay: Clock.minuteOfDay()))
        dispatch(UIAction.mealPickerOpened)
    }
}
