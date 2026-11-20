//
//  TimerMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class TimerMiddleware: Middleware {
    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        switch action {
        case TimerAction.startFastTapped:
            dispatch(StartFastThunk())
        case TimerAction.resumeTapped:
            dispatch(ResumeFastThunk())
        case TimerAction.resetTapped:
            dispatch(ResetFastThunk())
        case TimerAction.startEatingTapped:
            dispatch(StartEatingThunk())
        case TimerAction.continueFastingTapped:
            dispatch(ContinueFastingThunk())
        case TimerAction.goalMomentStarted:
            dispatch(CelebrateGoalThunk())
        default:
            break
        }
    }
}
