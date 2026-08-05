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

    /// Edge 6, waiting for a neutral moment on the timer — not over a running fast,
    /// not on the complete state, not over an animation.
    var revocationPending: Bool = false
    /// Edge 17, waiting for the next fast to start. It is armed at the same instant
    /// as the one above and shown much later, which is the whole point of decision 27.
    var goalChangePending: Bool = false
    /// The notice on screen right now, if any.
    var notice: ProNotice? = nil

    /// Restore ran and found nothing. Transient: the service block says so for a
    /// couple of seconds and goes back to being a link. Not a seventh offer state —
    /// after an empty restore the truth about this user is exactly S1.
    var showsNothingToRestore: Bool = false

    var isPro: Bool { entitlement == .pro }

    /// Whether the offer screen is up. Derived from the entry point rather than
    /// stored twice: the screen cannot be open without one, and cannot be closed
    /// while it still has one.
    var isOfferOpen: Bool { trigger != nil }

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
        case .idle:
            if entitlement == .unknown { return .unverified }
            // No product means no price, and the offer is a frame built around one.
            // A configuration error is not the user's unverified entitlement, so it
            // does not belong in S5 — Restore could never resolve it. It belongs in
            // the one state where saying "something broke" is true.
            return product == nil ? .failed(.other) : .offer
        }
    }
}
