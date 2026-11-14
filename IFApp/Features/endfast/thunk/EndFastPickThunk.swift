//
//  EndFastPickThunk.swift
//  IFApp
//

import Foundation
import Redux

struct EndFastChipThunk: Thunk {
    let offset: EndFastChipOffset

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let now = Clock.now().timeIntervalSince1970
        let timestamp = EndFastMath.resolve(offset, now: now,
                                            selected: app.endFastState.endTimestamp)
        dispatch(EndFastAction.chipPicked(timestamp: timestamp, latest: now))
    }
}

struct EndFastStepThunk: Thunk {
    let minutes: Int

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(EndFastAction.timeStepped(byMinutes: minutes,
                                           latest: Clock.now().timeIntervalSince1970))
    }
}
