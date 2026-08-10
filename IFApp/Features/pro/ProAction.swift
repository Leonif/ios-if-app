//
//  ProAction.swift
//  IFApp
//

import Redux

enum ProAction: Action {
    /// The offer screen opened, and from where.
    case offerOpened(trigger: PaywallTrigger)
    /// The offer screen was closed — by the user, or by itself after a purchase.
    case offerClosed

    /// A fast just ended having reached the quality threshold, so it has earned the
    /// one-time offer. Arming, not showing: the moment comes later, when the user
    /// leaves the complete state through the eating window.
    case autoOfferArmed
    /// The armed show is off. Dispatched by whoever invalidates the fast behind it —
    /// the rollback that puts the fast back in flight, and the Reset that throws it
    /// away. The one-time flag is untouched, so the next qualified fast arms again.
    case autoOfferCancelled

    /// A store lookup finished: what is owned and what is for sale, together, because
    /// they are answered by the same round trip and disagreeing halves are worse than
    /// a slightly later answer.
    case storeResolved(entitlement: Entitlement, product: ProProductInfo?)
    /// The entitlement changed under us — a purchase made elsewhere, an approved
    /// Ask to Buy, a refund, a family member leaving the group.
    case entitlementChanged(Entitlement)

    case purchaseStarted
    case purchaseCompleted
    /// Ask to Buy: the purchase exists but nobody has approved it yet.
    case purchasePending
    /// `cancelled` means the user backed out; the screen returns to the offer rather
    /// than to an error.
    case purchaseFailed(PurchaseFailure)

    case restoreStarted
    /// Restore ran and found the purchase.
    case restoreCompleted
    /// Restore ran and there was nothing to restore. Not an error: the screen goes
    /// back to the offer, now with a verified answer behind it.
    case restoreFoundNothing
    case restoreFailed(PurchaseFailure)
    /// The transient "nothing to restore" line has had its couple of seconds.
    case nothingToRestoreExpired

    /// A one-time notice reached its moment and is now on screen. Dispatched by
    /// whoever owns that moment: the timer flow for edge 6, the start thunk for
    /// edge 17.
    case noticeShown(ProNotice)
    case noticeDismissed
}
