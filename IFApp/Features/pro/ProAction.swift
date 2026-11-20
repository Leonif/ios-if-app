//
//  ProAction.swift
//  IFApp
//

import Redux

enum ProAction: Action {
    case offerOpened(trigger: PaywallTrigger)
    case offerClosed

    case autoOfferArmed
    case autoOfferCancelled

    case storeResolved(entitlement: Entitlement, product: ProProductInfo?)
    case entitlementChanged(Entitlement)

    case purchaseTapped
    case purchaseStarted
    case purchaseCompleted
    case purchasePending
    case purchaseFailed(PurchaseFailure)

    case restoreTapped
    case restoreStarted
    case restoreCompleted
    case restoreFoundNothing
    case restoreFailed(PurchaseFailure)
    case nothingToRestoreExpired

    case noticeShown(ProNotice)
    case noticeDismissed
}
