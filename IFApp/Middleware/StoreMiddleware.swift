//
//  StoreMiddleware.swift
//  IFApp
//
//  Owns the two things about the store that outlive any one screen: the entitlement
//  read at launch, and the listener for changes that arrive without anyone asking —
//  an approved Ask to Buy, a purchase made on another device, a refund, a family
//  member leaving the group.
//
//  The listener has to be running whenever the app is, not while some screen is up:
//  a refund can land on the idle timer, and the offer screen may never be opened at
//  all. Middleware is the only thing here with that lifetime and a dispatch.
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

    /// Idempotent: `appOpened` is dispatched once per launch today, but a second one
    /// must not leave two listeners racing to report the same transaction.
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
