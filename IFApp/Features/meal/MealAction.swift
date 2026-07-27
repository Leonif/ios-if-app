//
//  MealAction.swift
//  IFApp
//
//  Clock-dependent values (nowMinuteOfDay) are injected by thunks; the reducer stays pure.
//

import Redux

enum MealAction: Action {
    /// Seed the control to a specific past moment (the window-closed default), if
    /// still unset. Lights no chip: the value came from the app, not from a tap.
    case initialized(ateDay: Int, ateMin: Int)
    /// The ribbon moved. `minutesAgo` is already clamped to the domain by the thunk;
    /// any chip selection drops, the ribbon is the source of truth now.
    case scrubbed(minutesAgo: Int, nowMinuteOfDay: Int)
    /// A quick chip was tapped: it sets the value *and* stays lit.
    case chipPicked(idx: Int, minutesAgo: Int, nowMinuteOfDay: Int)
    /// An exact moment from the system date picker — deliberately off the snap grid.
    case exactTimePicked(ateDay: Int, ateMin: Int)
    /// Back to "now / fresh".
    case cleared
}
