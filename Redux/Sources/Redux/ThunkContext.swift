//
//  ThunkContext.swift
//  Redux
//

public final class ThunkContext<State: Equatable>: @unchecked Sendable {
    public let state: State
    public let dispatch: (Action) -> Void

    public init(state: State, dispatch: @escaping (Action) -> Void) {
        self.state = state
        self.dispatch = dispatch
    }
}
