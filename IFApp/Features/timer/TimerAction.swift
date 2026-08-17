//
//  TimerAction.swift
//  IFApp
//
//  Feature-namespaced actions. Timestamps are injected by thunks (reducers stay pure).
//

import Foundation
import Redux

enum TimerAction: Action {
    /// Begin a fast. `startTimestamp` already accounts for any staged elapsed time.
    /// `goalHours` is the goal this fast runs to — injected at dispatch and pinned in
    /// state, so it stops following the plan setting once the fast is under way.
    case started(startTimestamp: Double, goalHours: Double)
    /// End a fast. `qualifiesAsCompleted` = the fast reached its goal. Analytics-only:
    /// completed fasts are counted on `goalCelebrated`, not here.
    ///
    /// `backdatedMinutes` = how far behind the tap the confirmed end was placed. It
    /// rides in the action rather than being derived downstream because it is the
    /// difference between two moments and only one of them survives the reduce: the
    /// clock at the tap is gone by the time any middleware sees the state.
    case stopped(elapsed: TimeInterval, qualifiesAsCompleted: Bool, backdatedMinutes: Int)
    /// Undo of `.stopped` from the result screen: the same fast goes back in flight.
    /// `startTimestamp` is injected already shifted back by the staged elapsed, so the
    /// count picks up where it left off.
    ///
    /// Not `.started`: that one pins a fresh `goalHours` from the current plan and
    /// clears `hasCelebrated`, which would rewrite the goal this fast actually ran to
    /// and replay the goal moment (counting the session and the streak day twice).
    /// Undo restores, it does not begin.
    case stopUndone(startTimestamp: Double)
    /// Clear everything back to zero. `elapsed` = how long the fast had been running
    /// at the moment of the reset (staged value when it was not running). Analytics-only:
    /// the reducer zeroes everything either way. It travels in the action because the
    /// middleware sees post-reduce state, where the timer is already cleared.
    case reset(elapsed: TimeInterval)
    /// Manual ± adjustment. `runningStartTimestamp` is non-nil only when the fast is running.
    case timeAdjusted(newElapsed: TimeInterval, runningStartTimestamp: Double?)
    /// The goal-reached moment fired for the current fast (marks it so it plays once).
    /// `dayKey` = the local day the goal counts toward (see Clock.dayKey) — injected
    /// at dispatch so the reducer stays pure; a fast crossing midnight credits the
    /// day the goal was actually reached.
    /// `ownsFreeze` rides along for the same reason `dayKey` does: the protected day
    /// is Pro's, the entitlement lives in `ProState`, and the timer reducer is handed
    /// only its own substate. Read once, at the moment the goal lands, so a purchase
    /// or a refund arriving later cannot re-decide a streak already banked.
    case goalCelebrated(dayKey: String, ownsFreeze: Bool)
    /// Open the eating window. `startTimestamp` = when it opened (usually now).
    case eatingStarted(startTimestamp: Double)
    /// Close the eating window back to idle (window elapsed, or skipped).
    case eatingEnded
}
