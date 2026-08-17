//
//  EndFastPickThunk.swift
//  IFApp
//
//  The two controls that move the chosen end. Both go through a thunk rather than
//  straight to the reducer for the same reason: the right edge of the reachable
//  range is "now", and it moves while the sheet is open. A clamp against the bound
//  captured at open would start letting the future through the moment the user
//  paused to read.
//

import Foundation
import Redux

/// A preset chip. The row hands back what the chip *means* — minutes back from now,
/// or whole days back from the standing choice — and the moment is resolved here,
/// against the clock as it stands at the tap. The sheet redraws every second, so a
/// moment resolved in the view would be the moment of whichever frame the finger
/// happened to land on.
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

/// The exact-time control, ± one step.
struct EndFastStepThunk: Thunk {
    let minutes: Int

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(EndFastAction.timeStepped(byMinutes: minutes,
                                           latest: Clock.now().timeIntervalSince1970))
    }
}
