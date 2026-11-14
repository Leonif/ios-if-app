//
//  Middleware.swift
//  Redux
//

import Foundation

public struct DispatchFunction {
    private let dispatchAction: (Action) -> Void
    private let dispatchThunk: (Thunk) -> Void

    public init(
        dispatchAction: @escaping (Action) -> Void,
        dispatchThunk: @escaping (Thunk) -> Void
    ) {
        self.dispatchAction = dispatchAction
        self.dispatchThunk = dispatchThunk
    }

    public func callAsFunction(_ action: Action) {
        dispatchAction(action)
    }

    public func callAsFunction(_ thunk: Thunk) {
        dispatchThunk(thunk)
    }
}

public protocol Middleware {
    func handle<State: Equatable>(thunk: Thunk, state: State)
    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction)
}
