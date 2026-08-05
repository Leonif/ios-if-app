//
//  ProState.swift
//  IFApp
//
//  Everything the paid tier holds: what is owned, what is for sale, and what the
//  purchase machinery is doing. The offer screen's six states are derived here rather
//  than stored, so no code path can leave the screen in a state that contradicts the
//  entitlement it is selling.
//

struct ProState: Equatable, Sendable {
    var entitlement: Entitlement = .unknown
    /// nil until the store answers (and on every launch that never reaches it).
    var product: ProProductInfo? = nil
    var phase: PurchasePhase = .idle
    /// Which entry point opened the offer. Set when it opens and carried until it
    /// closes, because every purchase event has to say which door the user came in
    /// through — the distribution over triggers is the one readable result of 1.5.0.
    var trigger: PaywallTrigger? = nil

    var isPro: Bool { entitlement == .pro }

    /// Which of the six states the offer screen shows.
    ///
    /// An attempt in progress outranks everything: while the user is waiting on a
    /// payment, that is the only thing the screen can honestly be about. With nothing
    /// in flight, an unverified entitlement shows S5 rather than the offer — we do not
    /// invite someone to buy again what they may already own.
    var offerState: OfferState {
        switch phase {
        case .purchasing: return .purchasing
        case .awaitingApproval: return .awaitingApproval
        case let .failed(reason): return .failed(reason)
        case .restored: return .restored
        case .idle: return entitlement == .unknown ? .unverified : .offer
        }
    }
}
