//
//  StoreMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class StoreMiddleware: Middleware {
    private let store: StoreRepositoryProtocol
    private var listener: Task<Void, Never>?

    init(store: StoreRepositoryProtocol = container.inject()) {
        self.store = store
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let lifecycle = action as? AppLifecycleAction, case .appOpened = lifecycle else { return }
        startListening(dispatch: dispatch)
        dispatch(RefreshEntitlementThunk())
    }

    private func startListening(dispatch: DispatchFunction) {
        guard listener == nil else { return }
        let updates = store.entitlementUpdates()
        listener = Task {
            for await entitlement in updates {
                dispatch(ProAction.entitlementChanged(entitlement))
            }
        }
    }

    deinit { listener?.cancel() }
}
