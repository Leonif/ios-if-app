//
//  ResetFastThunk.swift
//  IFApp
//
//  Reset is not a completed session — no review prompt here.
//

import Foundation
import Redux

struct ResetFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState

        // Resolved exactly as StopFastThunk does, and for the same reason: this is the
        // last point where the elapsed time still exists. `fast_reset.elapsed_minutes`
        // is what separates a start-time correction (minutes) from giving up (hours).
        let now = Date().timeIntervalSince1970
        let elapsed = timer.isRunning
            ? max(0, now - timer.fastStartTimestamp)
            : timer.stagedElapsed

        dispatch(TimerAction.reset(elapsed: elapsed))
        dispatch(MealAction.cleared)
    }
}
