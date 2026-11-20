//
//  StoreMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class StoreMiddleware: Middleware {
    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        switch action {
        case AppLifecycleAction.appOpened:
            dispatch(SyncEntitlementThunk())
        case ProAction.purchaseTapped:
            dispatch(PurchaseProThunk())
        case ProAction.restoreTapped:
            dispatch(RestorePurchasesThunk())
        default:
            break
        }
    }
}
