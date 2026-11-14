//
//  CelebrateGoalThunk.swift
//  IFApp
//

import Redux

struct CelebrateGoalThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard timer.fastStartTimestamp > 0 else { return }

        let dayKey = Clock.goalDayKey(
            fastStart: timer.fastStartTimestamp,
            goalHours: app.activeGoalHours
        )
        dispatch(TimerAction.goalCelebrated(dayKey: dayKey, ownsFreeze: app.proState.isPro))
    }
}
