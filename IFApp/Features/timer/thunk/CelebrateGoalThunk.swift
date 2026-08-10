//
//  CelebrateGoalThunk.swift
//  IFApp
//
//  The goal-reached moment. Stamps the local day the goal counts toward — the day
//  the goal was *crossed* (`Clock.goalDayKey`), not the day this thunk happened to
//  run — so a back-dated fast whose goal landed before midnight credits the same day
//  the history screen already credits it to. The reducer stays pure and is idempotent,
//  so a second call (relaunch, scene-phase replay) changes nothing.
//

import Redux

struct CelebrateGoalThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        // Thunks run asynchronously: the fast can be ended between the frame that
        // saw the crossing and this line, and a start of 0 would stamp 1970.
        guard timer.fastStartTimestamp > 0 else { return }

        let dayKey = Clock.goalDayKey(
            fastStart: timer.fastStartTimestamp,
            goalHours: app.activeGoalHours
        )
        dispatch(TimerAction.goalCelebrated(dayKey: dayKey, ownsFreeze: app.proState.isPro))
    }
}
