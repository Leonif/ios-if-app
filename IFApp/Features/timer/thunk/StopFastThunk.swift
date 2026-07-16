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
        let goalHours = (Plan(rawValue: app.planState.planIdx) ?? .default).fastHours
        let qualifies = elapsed >= goalHours * 3600

        dispatch(TimerAction.stopped(elapsed: elapsed, qualifiesAsCompleted: qualifies))
    }
}
