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
    /// The picker was opened. Carries no value: it only marks where to come back to
    /// if the sheet is dismissed instead of confirmed.
    case pickerOpened
    /// The picker was dismissed — by the scrim, and by anything else that closes the
    /// sheet without confirming. Puts the answer back as it stood on open.
    ///
    /// A separate case from `cleared` because they mean opposite things: `cleared`
    /// says "there is no answer any more", this one says "keep the answer you had".
    /// Dismissing a sheet opened over a seeded window-close time must not throw the
    /// seed away.
    case pickerDismissed
    /// The picker was confirmed. Changes no value — the answer already stands — and
    /// exists only to spend the way back to the one before it.
    ///
    /// Without it the snapshot outlives the confirm, and a `pickerDismissed` arriving
    /// afterwards would quietly undo a committed answer. Nothing dispatches one today;
    /// the next way of closing this sheet that somebody adds would, and it would fail
    /// exactly the way this pair of cases was written to stop.
    case pickerConfirmed
}
