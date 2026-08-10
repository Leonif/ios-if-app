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

    /// T1', spent. The one-time offer is one time for the life of the install, so
    /// this is the one thing about the offer that outlives a launch — loaded at
    /// bootstrap, written back on the fact of a show and on nothing else.
    ///
    /// It lives in the app's preferences (`ProOfferRepository`), so a cold start and
    /// an App Store update carry it and a delete-and-reinstall clears it. The second
    /// half is accepted, not a defect: what keeps the offer away from someone who
    /// already paid is the entitlement check, not this flag, and a flag that survived
    /// deletion would only mean a person who reinstalled never sees the offer at all.
    var autoOfferShown: Bool = false

    /// A qualified fast finished and the offer it earned has not been shown yet.
    ///
    /// Deliberately **not** persisted. The plan belongs to the session that finished
    /// the fast: a session that ends without showing simply drops it, the flag above
    /// stays whole, and the next qualified fast arms a new one. Persisting it would
    /// make the offer something that greets a cold start with no fast behind it —
    /// the ambush rule T1' exists to prevent.
    var autoOfferArmed: Bool = false

    /// The native review request went out this launch. The offer stands down for the
    /// rest of it: both are interruptions and only one of them is an asset we keep.
    var reviewPromptedThisSession: Bool = false

    /// Restore ran and found nothing. Transient: the service block says so for a
    /// couple of seconds and goes back to being a link. Not a seventh offer state —
    /// after an empty restore the truth about this user is exactly S1.
    var showsNothingToRestore: Bool = false

    var isPro: Bool { entitlement == .pro }

    /// Whether the offer screen is up. Derived from the entry point rather than
    /// stored twice: the screen cannot be open without one, and cannot be closed
    /// while it still has one.
    var isOfferOpen: Bool { trigger != nil }

    /// Whether T1' is owed and nothing on the entitlement side forbids showing it.
    ///
    /// Not "show it now": *when* is the business of the screen that renders the
    /// eating window (`TimerFlowView.scheduleAutoOffer`), because the moment is
    /// defined by that card being on screen and settled. This side answers only
    /// "may it", and it is one definition because both the scheduling and the
    /// re-check on arrival ask it.
    ///
    /// Every condition here is a *suppression*, and none of them spends
    /// `autoOfferShown` — that is the whole mechanism by which a suppressed show is
    /// a postponement rather than a loss:
    ///
    /// - `entitlement == .free` rather than `!isPro`: `unknown` locks like free but
    ///   must never open the offer by itself (edge 16 / PW-9). The store may answer
    ///   seconds later; by then this moment has passed and the offer moves on;
    /// - `product != nil`: no price means no offer to make. We do not open a screen
    ///   that cannot sell;
    /// - `phase == .idle`: an attempt already in flight (an Ask to Buy still out) is
    ///   not something to interrupt with an invitation to buy the same thing.
    var autoOfferPending: Bool {
        autoOfferArmed
            && !autoOfferShown
            && !reviewPromptedThisSession
            && entitlement == .free
            && product != nil
            && phase == .idle
            && !isOfferOpen
    }

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
