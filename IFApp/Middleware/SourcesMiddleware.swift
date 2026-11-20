//
//  SourcesMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class SourcesMiddleware: Middleware {
    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard case let AppLifecycleAction.sourceOriginalOpened(_, url) = action else { return }
        dispatch(OpenExternalLinkThunk(url: url))
    }
}
