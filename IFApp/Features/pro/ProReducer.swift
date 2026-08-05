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
        // the last time the screen was up is not news about this one. A pending
        // approval is not left over — the request is still out — so the screen opens
        // on S4 rather than inviting a second purchase of the same thing.
        if !newState.phase.outlivesOffer { newState.phase = .idle }
        newState.showsNothingToRestore = false

    case .offerClosed:
        newState.trigger = nil
        // Same rule, and the one PW9 was about: walking away from the offer is not an
        // answer from whoever approves the purchase. The Pro row in About IF24 reads
        // this phase, and it has to keep saying "awaiting approval" until the approval
        // (or a failure) actually arrives — edge 18 / PW-13.
        if !newState.phase.outlivesOffer { newState.phase = .idle }
        newState.showsNothingToRestore = false

    case let .storeResolved(entitlement, product):
        newState.entitlement = entitlement
        newState.product = product

    case let .entitlementChanged(entitlement):
        // Losing a right that was verifiably held is the one transition the user has
        // to be told about — a refund, or a family member leaving the group. Both
        // notices are armed here and shown much later, at two different moments.
        if state.entitlement == .pro, entitlement != .pro {
            newState.revocationPending = true
            newState.goalChangePending = true
        }
        newState.entitlement = entitlement
        if entitlement == .pro {
            // Having it again makes both queued notices false, whether they were
            // queued a second ago or a week ago.
            newState.revocationPending = false
            newState.goalChangePending = false
            // An approved Ask to Buy arrives here: the wait is over, so the screen
            // stops saying it is waiting. Nothing else about a change of entitlement
            // is a statement about an attempt in progress.
            if newState.phase == .awaitingApproval { newState.phase = .idle }
        }

    case .purchaseStarted, .restoreStarted:
        newState.phase = .purchasing
        newState.showsNothingToRestore = false

    case .purchaseCompleted:
        newState.entitlement = .pro
        newState.phase = .idle
        // A bought offer has nothing left to say, so it closes itself — there is no
        // seventh "just purchased" state to land on. Clearing the entry point is what
        // closes it; the analytics middleware reads the trigger off its pre-reduce
        // snapshot, so `purchase_completed` still carries the door it came in through.
        newState.trigger = nil

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
        // Leaving S5 is its own feedback; the transient line below is for the two
        // surfaces where the frame would otherwise not move at all.
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

    return newState
}
