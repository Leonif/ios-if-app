//
//  QuickMealChipThunk.swift
//  IFApp
//
//  Applies a "N minutes ago" quick chip relative to the current clock.
//

import Redux

struct QuickMealChipThunk: Thunk {
    let minutesAgo: Int

    init(minutesAgo: Int) { self.minutesAgo = minutesAgo }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(MealAction.quickChip(minutesAgo: minutesAgo, nowMinuteOfDay: Clock.minuteOfDay()))
    }
}
