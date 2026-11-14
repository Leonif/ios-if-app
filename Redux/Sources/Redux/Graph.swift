//
//  Graph.swift
//  Redux
//

public class Graph<State: Equatable> {
    private let store: Store<State>

    public var state: State {
        store.getCurrentState()
    }

    public init(store: Store<State>) {
        self.store = store
    }
}
