//
//  StopFastThunk.swift
//  IFApp
//
//  Computes the final elapsed time and whether the fast reached its goal.
//

import Foundation
import Redux

struct StopFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState

        let now = Date().timeIntervalSince1970
        let elapsed = timer.isRunning
            ? max(0, now - timer.fastStartTimestamp)
            : timer.stagedElapsed
        // Analytics-only flag (`fast_stopped.completed`) — it gates nothing. The
        // review prompt now hangs off reaching the goal, not off ending the fast.
        // The goal this fast was started with — not the plan as it stands now, which
        // the user may have changed (or lost the entitlement for) mid-fast.
        let qualifies = elapsed >= app.activeGoalHours * 3600

        dispatch(TimerAction.stopped(elapsed: elapsed, qualifiesAsCompleted: qualifies))

        // T1'. The fast that just ended is the only thing that can arm the one-time
        // offer, and this is the last point where its elapsed time still exists —
        // `.stopped` stages it, but the goal it ran to is resolved here.
        //
        // Arming is not showing. The moment comes later, once the user has left the
        // complete state through the eating window; everything in between (a rollback,
        // a Reset, a review prompt, the session simply ending) cancels or suppresses
        // it without costing the show.
        if OfferQualification.qualifies(elapsed: elapsed, goalHours: app.activeGoalHours) {
            dispatch(ProAction.autoOfferArmed)
        }
    }
}
