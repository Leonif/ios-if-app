//
//  ResetFastThunk.swift
//  IFApp
//
//  Reset is not a completed session — no review prompt here.
//

import Redux

struct ResetFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(TimerAction.reset)
    }
}
