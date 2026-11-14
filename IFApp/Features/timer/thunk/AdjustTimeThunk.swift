//
//  AdjustTimeThunk.swift
//  IFApp
//

import Foundation
import Redux

struct AdjustTimeThunk: Thunk {
    let interval: TimeInterval

    init(by interval: TimeInterval) {
        self.interval = interval
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState

        let now = Date().timeIntervalSince1970
        let current = timer.elapsed(at: now)
        let newElapsed = max(0, current + interval)
        let runningStart: Double? = timer.isRunning ? now - newElapsed : nil

        dispatch(TimerAction.timeAdjusted(newElapsed: newElapsed, runningStartTimestamp: runningStart))
    }
}
