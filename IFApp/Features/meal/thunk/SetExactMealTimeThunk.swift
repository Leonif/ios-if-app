//
//  SetExactMealTimeThunk.swift
//  IFApp
//
//  The demoted precise path: a moment picked in the system date picker. It is not
//  rounded to the ribbon's snap grid — someone who went looking for 7:52 PM wants
//  7:52 PM, and snapping it would take away the only reason to open the picker.
//

import Foundation
import Redux

struct SetExactMealTimeThunk: Thunk {
    let date: Date

    init(_ date: Date) { self.date = date }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let now = Clock.now()
        // The picker's own range already stops at "now", but the clamp is what makes
        // a future start unrepresentable rather than merely unreachable.
        let mins = MealMath.minutesAgo(of: date, now: now)
        guard mins > 0 else {
            dispatch(MealAction.cleared)
            return
        }
        let moment = MealMath.moment(minutesAgo: mins, nowMinuteOfDay: Clock.minuteOfDay(now))
        dispatch(MealAction.exactTimePicked(ateDay: moment.ateDay, ateMin: moment.ateMin))
    }
}
