//
//  PurchaseProThunk.swift
//  IFApp
//

import Redux

struct PurchaseProThunk: Thunk {
    private let store: StoreRepositoryProtocol

    init(store: StoreRepositoryProtocol = container.inject()) {
        self.store = store
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState, !app.proState.isPro else { return }

        dispatch(ProAction.purchaseStarted)

        switch await store.purchase() {
        case .purchased:
            dispatch(ProAction.purchaseCompleted)
        case .pending:
            dispatch(ProAction.purchasePending)
        case .cancelled:
            dispatch(ProAction.purchaseFailed(.cancelled))
        case let .failed(reason):
            dispatch(ProAction.purchaseFailed(reason))
        }
    }
}
