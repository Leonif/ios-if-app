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
            // The line retires itself. The wait lives here rather than in the view
            // because a view that schedules its own delayed work owns a timer whose
            // lifetime is the frame's, not the answer's.
            try? await Task.sleep(nanoseconds: Self.transientNanoseconds)
            dispatch(ProAction.nothingToRestoreExpired)
        case let .failed(reason):
            dispatch(ProAction.restoreFailed(reason))
        }
    }

    /// Long enough to be read once, short enough that it is gone before the next tap.
    private static let transientNanoseconds: UInt64 = 2_500_000_000
}
