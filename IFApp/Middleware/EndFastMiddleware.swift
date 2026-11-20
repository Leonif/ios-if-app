//
//  EndFastMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class EndFastMiddleware: Middleware {
    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        switch action {
        case EndFastAction.openTapped:
            dispatch(OpenEndFastThunk())
        case let EndFastAction.chipTapped(offset):
            dispatch(EndFastChipThunk(offset: offset))
        case let EndFastAction.stepTapped(minutes):
            dispatch(EndFastStepThunk(minutes: minutes))
        case EndFastAction.confirmTapped:
            dispatch(ConfirmEndFastThunk())
        default:
            break
        }
    }
}
