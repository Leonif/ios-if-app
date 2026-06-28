//
//  Thunk.swift
//  HelloWorldReduxTry
//
//  Created by LEONID NIFANTIJEV on 17.08.2025.
//

public protocol Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async
}
