//
//  ProReducer.swift
//  IFApp
//

import Redux

func proReducer(state: ProState, action: Action) -> ProState {
    var newState = state

    switch action as? ProAction {
    case let .offerOpened(trigger):
        newState.trigger = trigger
        if trigger == .fastFinished {
            newState.autoOfferShown = true
            newState.autoOfferArmed = false
        }
        if !newState.phase.outlivesOffer { newState.phase = .idle }
        newState.showsNothingToRestore = false

    case .offerClosed:
        newState.trigger = nil
        if !newState.phase.outlivesOffer { newState.phase = .idle }
        newState.showsNothingToRestore = false

    case .autoOfferArmed:
        if !newState.autoOfferShown { newState.autoOfferArmed = true }

    case .autoOfferCancelled:
        newState.autoOfferArmed = false

    case let .storeResolved(entitlement, product):
        newState.entitlement = entitlement
        newState.product = product

    case let .entitlementChanged(entitlement):
        if state.isPro, entitlement != .pro {
            newState.revocationPending = true
            newState.goalChangePending = true
        }
        newState.entitlement = entitlement
        if entitlement == .pro {
            newState.revocationPending = false
            newState.goalChangePending = false
            if newState.phase == .awaitingApproval { newState.phase = .granted(.approved) }
        }

    case .purchaseStarted, .restoreStarted:
        newState.phase = .purchasing
        newState.showsNothingToRestore = false

    case .purchaseCompleted:
        newState.entitlement = .pro
        newState.phase = .granted(.purchased)

    case .purchasePending:
        newState.phase = .awaitingApproval

    case let .purchaseFailed(reason), let .restoreFailed(reason):
        newState.phase = reason == .cancelled ? .idle : .failed(reason)

    case .restoreCompleted:
        newState.entitlement = .pro
        newState.phase = .granted(.restored)

    case .restoreFoundNothing:
        newState.entitlement = .free
        newState.phase = .idle
        newState.showsNothingToRestore = state.entitlement != .unknown

    case .nothingToRestoreExpired:
        newState.showsNothingToRestore = false

    case let .noticeShown(notice):
        newState.notice = notice
        switch notice {
        case .entitlementRevoked: newState.revocationPending = false
        case .goalChanged: newState.goalChangePending = false
        }

    case .noticeDismissed:
        newState.notice = nil

    case .none:
        break
    }

    if case AppLifecycleAction.reviewPrompted = action {
        newState.reviewPromptedThisSession = true
    }

    if newState.isPro, newState.phase == .idle {
        newState.trigger = nil
    }

    return newState
}
