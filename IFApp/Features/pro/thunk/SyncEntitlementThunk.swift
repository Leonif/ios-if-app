//
//  SyncEntitlementThunk.swift
//  IFApp
//

import Redux

struct SyncEntitlementThunk: Thunk {
    private let store: StoreRepositoryProtocol

    init(store: StoreRepositoryProtocol = container.inject()) {
        self.store = store
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let updates = store.entitlementUpdates()
        let resolved = await store.refresh()
        dispatch(ProAction.storeResolved(entitlement: resolved.entitlement, product: resolved.product))
        for await entitlement in updates {
            dispatch(ProAction.entitlementChanged(entitlement))
        }
    }
}
