//
//  EndFastStepThunk.swift
//  IFApp
//

import Foundation
import Redux

struct EndFastStepThunk: Thunk {
    let minutes: Int

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(EndFastAction.timeStepped(byMinutes: minutes,
                                           latest: Clock.now().timeIntervalSince1970))
    }
}
