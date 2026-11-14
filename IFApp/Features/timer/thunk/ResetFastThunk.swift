//
//  ResetFastThunk.swift
//  IFApp
//

import Foundation
import Redux

struct ResetFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState

        let now = Date().timeIntervalSince1970
        let elapsed = timer.isRunning
            ? max(0, now - timer.fastStartTimestamp)
            : timer.stagedElapsed

        dispatch(TimerAction.reset(elapsed: elapsed))
        dispatch(MealAction.cleared)
        dispatch(ProAction.autoOfferCancelled)
    }
}
