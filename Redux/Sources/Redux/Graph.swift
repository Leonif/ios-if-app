//
//  Graph.swift
//  Redux
//
//  Created by Leonid-user on 12.10.2025.
//

public class Graph<State: Equatable> {
    private let store: Store<State>

    // Graph reads state from store on each access
    public var state: State {
        store.getCurrentState()
    }

    public init(store: Store<State>) {
        self.store = store
    }
}
