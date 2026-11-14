//
//  OpenEndFastThunk.swift
//  IFApp
//

import Foundation
import Redux

struct OpenEndFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard timer.isRunning, timer.fastStartTimestamp > 0 else { return }

        let now = Clock.now().timeIntervalSince1970
        let elapsed = timer.elapsed(at: now)
        let goalSeconds = app.activeGoalHours * 3600
        let secondsLeft = goalSeconds - elapsed

        let entry: EndFastEntry
        let defaultEnd: Double
        if secondsLeft > 0 {
            let minutesLeft = Int(ceil(secondsLeft / 60))
            entry = EndFastMath.isNearGoal(secondsLeft: secondsLeft)
                ? .nearGoal(minutesLeft: max(1, minutesLeft))
                : .ordinary
            defaultEnd = now
        } else if -secondsLeft >= EndFastState.overtimeNeutralThreshold {
            entry = .overtime(secondsPastGoal: -secondsLeft)
            defaultEnd = timer.fastStartTimestamp + goalSeconds
        } else {
            entry = .ordinary
            defaultEnd = now
        }

        dispatch(EndFastAction.opened(
            entry: entry,
            endTimestamp: defaultEnd,
            fastStartTimestamp: timer.fastStartTimestamp,
            earliest: timer.fastStartTimestamp + EndFastState.minimumFastDuration,
            latest: now
        ))
    }
}
