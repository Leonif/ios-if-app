//
//  ProState.swift
//  IFApp
//

struct ProState: Equatable, Sendable {
    var entitlement: Entitlement = .unknown
    var product: ProProductInfo? = nil
    var phase: PurchasePhase = .idle
    var trigger: PaywallTrigger? = nil

    var revocationPending: Bool = false
    var goalChangePending: Bool = false
    var notice: ProNotice? = nil

    var autoOfferShown: Bool = false

    var autoOfferArmed: Bool = false

    var reviewPromptedThisSession: Bool = false

    var showsNothingToRestore: Bool = false

    var isPro: Bool { entitlement == .pro }

    var isVerifiedFree: Bool { entitlement == .free }

    var isOfferOpen: Bool { trigger != nil }

    var autoOfferPending: Bool {
        autoOfferArmed
            && !autoOfferShown
            && !reviewPromptedThisSession
            && isVerifiedFree
            && product != nil
            && phase == .idle
            && !isOfferOpen
    }

    var offerState: OfferState {
        switch phase {
        case .purchasing: return .purchasing
        case .awaitingApproval: return .awaitingApproval
        case let .failed(reason): return .failed(reason)
        case let .granted(source): return .granted(source)
        case .idle:
            if entitlement == .unknown { return .unverified }
            return product == nil ? .failed(.other) : .offer
        }
    }
}
