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
        if state.isPro, entitlement != .pro {
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

    // The offer does not stand open in front of someone who already owns it. Stated
    // once, over the state, rather than three times over the three ways the right can
    // arrive: buying it here, an Ask to Buy approved minutes later, and the store
    // answering `.pro` for a purchase made elsewhere are different actions with the
    // same consequence — there is nothing left to sell.
    //
    // The condition is `idle` and not "the screen shows S1", because idle is exactly
    // "nothing in flight to be about": every other phase is feedback on an attempt and
    // has its own frame to finish in (S2 while it settles, S4 while approval is out,
    // S6 for the restore confirmation, S3 for a failure worth reading). With the
    // machinery idle, an open offer is only ever an invitation to buy — and the tap it
    // invites does nothing at all, since `PurchaseProThunk` guards on `isPro`.
    //
    // Clearing the entry point is what closes the screen; there is no seventh "just
    // purchased" state to land on. Analytics is unaffected: the middleware reads the
    // trigger off its pre-reduce snapshot, so `purchase_completed` still carries the
    // door the user came in through.
    //
    // Standing over the whole switch, it also refuses to *open* the offer for an
    // owner: `offerOpened` sets the entry point and this takes it straight back. That
    // is deliberate and today unreachable — all three doors are shut from outside
    // (`AboutIF24View.opensOffer`, the history export button, the plan editor) — but
    // if a fourth one is ever added without its own guard, note that the analytics
    // middleware logs `paywall_shown` on the action, so it would report a screen that
    // never appeared. The guard belongs on the door, not here.
    if newState.isPro, newState.phase == .idle {
        newState.trigger = nil
    }

    return newState
}
