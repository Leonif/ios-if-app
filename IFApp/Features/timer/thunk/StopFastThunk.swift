//
//  StopFastThunk.swift
//  IFApp
//
//  Computes the final elapsed time and whether it counts toward the review gate.
//

import Foundation
import Redux

struct StopFastThunk: Thunk {
    /// A session must reach this length to count as "completed" (filters accidental start/stop).
    private let minSessionDurationForReview: TimeInterval = 8 * 3600

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState

        let now = Date().timeIntervalSince1970
        let elapsed = timer.isRunning
            ? max(0, now - timer.fastStartTimestamp)
            : timer.stagedElapsed
        let qualifies = elapsed >= minSessionDurationForReview

        dispatch(TimerAction.stopped(elapsed: elapsed, qualifiesAsCompleted: qualifies))
    }
}
