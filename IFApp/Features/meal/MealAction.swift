//
//  MealAction.swift
//  IFApp
//
//  Every case carries a distance in minutes and nothing else. There is deliberately
//  no `nowMinuteOfDay` here: the picker's value *is* a distance (see `MealState`),
//  so no case needs a clock to be applied, and the reducer stays pure without one
//  being injected. The moment is resolved once, at confirm time, against the clock
//  of that instant.
//

import Redux

enum MealAction: Action {
    /// Seed the control to a distance the app worked out itself (the window-closed
    /// default), if still unset. Lights no chip: the value came from the app, not
    /// from a tap.
    case initialized(minutesAgo: Int)
    /// The ribbon moved. Any chip selection drops — the ribbon is the source of
    /// truth now.
    case scrubbed(minutesAgo: Int)
    /// A quick chip was tapped: it sets the value *and* stays lit.
    case chipPicked(idx: Int, minutesAgo: Int)
    /// An exact moment from the system date picker, as a distance — deliberately
    /// off the ribbon's snap grid.
    case exactTimePicked(minutesAgo: Int)
    /// Back to "now / fresh".
    case cleared
}
