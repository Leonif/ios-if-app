//
//  RestorePurchasesThunk.swift
//  IFApp
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
            try? await Task.sleep(nanoseconds: Self.transientNanoseconds)
            dispatch(ProAction.nothingToRestoreExpired)
        case let .failed(reason):
            dispatch(ProAction.restoreFailed(reason))
        }
    }

    private static let transientNanoseconds: UInt64 = 2_500_000_000
}
