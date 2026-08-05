//
//  RestorePurchasesThunk.swift
//  IFApp
//
//  Restore purchases. It is the only way back to Pro on a new device — there is no
//  account, by design — and the first action offered when the entitlement has not
//  been verified.
//

import Redux

struct RestorePurchasesThunk: Thunk {
    private let store: StoreRepositoryProtocol

    init(store: StoreRepositoryProtocol = container.inject()) {
        self.store = store
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        dispatch(ProAction.restoreStarted)

        switch await store.restore() {
        case .restored:
            dispatch(ProAction.restoreCompleted)
        case .nothingToRestore:
            dispatch(ProAction.restoreFoundNothing)
        case let .failed(reason):
            dispatch(ProAction.restoreFailed(reason))
        }
    }
}
