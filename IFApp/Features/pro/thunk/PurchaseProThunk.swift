//
//  PurchaseProThunk.swift
//  IFApp
//
//  The Buy button, end to end: mark the attempt, run Apple's sheet, report how it
//  ended. The four endings are separate actions rather than one with a flag, because
//  they lead to four different states of the offer screen.
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
