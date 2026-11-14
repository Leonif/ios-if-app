//
//  Thunk.swift
//  Redux
//

public protocol Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async
}
