//
//  StartFastThunk.swift
//  IFApp
//
//  Reads the clock (a side effect) and dispatches a pure `.started` action.
//

import Foundation
import Redux

struct StartFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard !timer.isRunning else { return }

        let now = Date().timeIntervalSince1970
        // Carry any staged elapsed time into the start so the count continues from there.
        let startTimestamp = now - timer.stagedElapsed
        dispatch(TimerAction.started(startTimestamp: startTimestamp))
    }
}
