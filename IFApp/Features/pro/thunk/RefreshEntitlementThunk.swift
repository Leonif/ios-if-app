//
//  RefreshEntitlementThunk.swift
//  IFApp
//
//  Asks the store what this install owns and what the product costs. One thunk for
//  both because they are one round trip, and because the answer to "is it owned"
//  depends on whether the store could be reached at all — which is what the product
//  lookup establishes.
//

import Redux

struct RefreshEntitlementThunk: Thunk {
    private let store: StoreRepositoryProtocol

    init(store: StoreRepositoryProtocol = container.inject()) {
        self.store = store
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let resolved = await store.refresh()
        dispatch(ProAction.storeResolved(entitlement: resolved.entitlement, product: resolved.product))
    }
}
