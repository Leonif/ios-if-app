//
//  ProReducer.swift
//  IFApp
//
//  Pure and synchronous. Every transition between the six offer states is here and
//  nowhere else — the screen renders `offerState`, it does not decide it.
//

import Redux

func proReducer(state: ProState, action: Action) -> ProState {
    var newState = state

    switch action as? ProAction {
    case let .offerOpened(trigger):
        newState.trigger = trigger
        // A fresh presentation starts clean: an error or a confirmation left over from
        // the last time the screen was up is not news about this one.
        newState.phase = .idle

    case .offerClosed:
        newState.trigger = nil
        newState.phase = .idle

    case let .storeResolved(entitlement, product):
        newState.entitlement = entitlement
        newState.product = product

    case let .entitlementChanged(entitlement):
        newState.entitlement = entitlement
        // An approved Ask to Buy arrives here: the wait is over, so the screen stops
        // saying it is waiting. Nothing else about a change of entitlement is a
        // statement about an attempt in progress.
        if entitlement == .pro, newState.phase == .awaitingApproval {
            newState.phase = .idle
        }

    case .purchaseStarted, .restoreStarted:
        newState.phase = .purchasing

    case .purchaseCompleted:
        newState.entitlement = .pro
        newState.phase = .idle

    case .purchasePending:
        newState.phase = .awaitingApproval

    case let .purchaseFailed(reason), let .restoreFailed(reason):
        // Backing out of Apple's sheet is not a failure to report: the offer stays
        // exactly as it was, which is what the user asked for by cancelling.
        newState.phase = reason == .cancelled ? .idle : .failed(reason)

    case .restoreCompleted:
        newState.entitlement = .pro
        newState.phase = .restored

    case .restoreFoundNothing:
        // Nothing to restore is an answer, not an error: it also settles an
        // entitlement that may have been unknown until now, so the screen leaves S5.
        newState.entitlement = .free
        newState.phase = .idle

    case .none:
        break
    }

    return newState
}
