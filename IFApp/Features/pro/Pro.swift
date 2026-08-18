//
//  Pro.swift
//  IFApp
//
//  The vocabulary of the paid tier: what the app knows about the entitlement, what
//  the offer screen can be showing, and the fixed values that travel to analytics.
//
//  One non-consumable, bought once, kept for good — there is no subscription, no
//  renewal and no account, so "does this install own Pro" is the whole model.
//

import Foundation

enum ProCatalog {
    /// The App Store product identifier. It must match, character for character, the
    /// in-app purchase created in App Store Connect and the one in `IFApp.storekit`
    /// used for local testing.
    ///
    /// Created in App Store Connect on 05.08.2026 (Apple ID 6798140298). The string is
    /// not derived from the bundle id: `simple-L.if-app.com` has dashes, and Apple
    /// allows only letters, digits, underscores and dots in a product identifier. It
    /// is also permanent — a deleted product does not release its id for reuse.
    static let productID = "if24.pro.lifetime"
}

/// What the app knows about the Pro entitlement. Three states, not two: on a fresh
/// install that has never reached the store, "we have not checked" is a different
/// fact from "not bought", and reading the first as the second is what tells a paying
/// user their purchase is gone (edge case 16 / PW-9).
enum Entitlement: String, Equatable, Sendable {
    /// Verified: this install owns Pro.
    case pro
    /// Verified: this install does not own Pro.
    case free
    /// Not verified yet. Gating behaves as `free` — we never hand out Pro on a guess —
    /// but the offer never opens by itself here, and a tap on a lock leads to
    /// "purchases not checked yet" with Restore as the first action.
    case unknown

    /// True while Pro features stay locked. `unknown` locks like `free` on purpose.
    var isLocked: Bool { self != .pro }

    /// The `pro_status` user property. A fixed, unlocalised list — `unknown` is a
    /// value of its own, not folded into `free`, or the property would say the app
    /// knows something it does not.
    var analyticsValue: String { rawValue }
}

/// Which finished fasts may carry the one-time offer (rule T1').
///
/// A fast abandoned in the first minutes does not qualify, for two reasons that pull
/// the same way: the first paid request in someone's life should not land on their
/// first failure, and — the half that costs money — a fast like that must not spend
/// the single show this install will ever get.
enum OfferQualification {
    /// The share of its goal a fast has to reach. A constant rather than logic: the
    /// final value comes from the distribution of `fast_stopped.duration_hours`, so
    /// tuning it is changing this number and nothing else.
    static let minimumGoalFraction = 0.5

    /// Reaching the goal needs no branch of its own — a fast that reached its goal is
    /// at 100% of it, which is already past the fraction above.
    ///
    /// `goalHours` is the goal the fast actually ran to (`AppState.activeGoalHours`),
    /// not the plan as it stands now: a plan changed mid-fast must not re-decide
    /// whether the fast that just ended was worth an offer.
    static func qualifies(elapsed: TimeInterval, goalHours: Double) -> Bool {
        goalHours > 0 && elapsed >= goalHours * 3600 * minimumGoalFraction
    }
}

/// Where the offer was opened from. The raw values are the GA4 `trigger` parameter:
/// a fixed ASCII list, never a string that also appears on screen. They are named
/// after the action, not the ordinal — the offer routinely appears on a user's third
/// or fifth fast, so `first_fast` would describe something that did not happen.
enum PaywallTrigger: String, Equatable, Sendable {
    /// T1': the first qualified finished fast, after the user left the complete state.
    case fastFinished = "fast_finished"
    /// T3: the Custom row in the plan editor.
    case planCustom = "plan_custom"
    /// T2: a broken streak, offering the freeze.
    case streakBreak = "streak_break"
    /// T4: a permanent entry the user had to go looking for — the Pro row in the
    /// About IF24 sheet, and the locked export in History.
    case manual
    /// The `Pro` control in the timer header. Kept apart from `manual` on purpose:
    /// that value means "the user went looking for the offer", this one means "the
    /// door was on screen and got tapped", and the whole point of putting a door on
    /// the home screen is the hypothesis that it becomes the main manual entry. Folded
    /// into `manual` it would make the one number this release exists to read —
    /// the distribution over triggers — unreadable.
    case home
    /// No entry point on record. Not a door and never dispatched: it is what the
    /// reporting falls back to for an event raised while no offer is open, which
    /// today means restore run from the About sheet's own button.
    ///
    /// It exists because `manual` used to serve as both — its own value and the
    /// fallback — so the one column the release is read by counted two different
    /// things at once, and a restore nobody opened an offer for inflated the very
    /// door `home` has to be compared against. A value that means "we do not know"
    /// has to be visibly absent from the distribution, not hidden inside a door.
    case unknown
}

/// Why a purchase attempt ended without Pro. Raw values are the GA4 `reason`
/// parameter, same fixed-list rule as `trigger`.
enum PurchaseFailure: String, Equatable, Hashable, Sendable {
    /// The user backed out of Apple's sheet. Not an error state on screen.
    case cancelled
    /// The store could not be reached. This is the one distinction the offer's error
    /// state renders differently — two bodies, one visual state (S3-A / S3-B).
    case network
    /// Ask to Buy: the purchase is waiting for someone else's approval.
    case pending
    case other
}

/// The store product as the offer screen needs it.
struct ProProductInfo: Equatable, Sendable {
    let id: String
    /// The store's own formatted price ("$6.99", "¥1,000", "COP 29.900,00"). Rendered
    /// as one string and never taken apart: currency position, digits and separators
    /// are the storefront's business, not ours.
    let displayPrice: String
}

/// How the right arrived. It never changes what the user owns or what the
/// confirmation frame looks like — only the words on it, because "you just paid",
/// "your purchase came back" and "someone approved it for you" are three different
/// things to have happen to you and one thing to own.
enum EntitlementSource: Equatable, Hashable, Sendable {
    case purchased
    case restored
    case approved
}

/// What the purchase machinery is doing right now. Distinct from the entitlement:
/// it is about the attempt in progress, not about what the user owns.
enum PurchasePhase: Equatable, Sendable {
    case idle
    /// Apple's sheet is up or the transaction is being settled.
    case purchasing
    /// Ask to Buy — waiting for a parent's approval. Not a failure the user caused;
    /// it resolves later through `Transaction.updates`, with no relaunch.
    case awaitingApproval
    case failed(PurchaseFailure)
    /// The right is in hand and has not been confirmed to the user yet. Every way
    /// of coming by it lands here: money changing hands is not allowed to be quieter
    /// than a free Restore was.
    case granted(EntitlementSource)

    /// Whether the phase describes something still happening off the offer screen,
    /// and so survives that screen being opened or closed. Ask to Buy is the only
    /// one: the request is out with whoever approves it and resolves through
    /// `Transaction.updates` whenever they get to it, which can be long after the
    /// user walked away. Every other phase is feedback about one presentation and
    /// says nothing about the next (edge 18 / PW-13).
    var outlivesOffer: Bool { self == .awaitingApproval }
}

/// The two things the app has to say after the entitlement goes away. They share
/// one sheet and differ only in when it appears: the first at the next neutral
/// moment, the second at the next fast that has to run to a different goal.
///
/// They are deliberately not shown together. Told at once, "Pro is gone" swallows
/// "and your goal is now sixteen hours" — and the second is the one that changes
/// what the timer does.
enum ProNotice: Equatable, Sendable {
    /// Edge 6. The reason is never named: refund and leaving a Family Sharing group
    /// are the same fact to the user, and one key covers both.
    case entitlementRevoked
    /// Edge 17. The other half of edge 9: the fast in flight was allowed to finish
    /// on its custom goal, so the next one starting shorter has to be said out loud.
    case goalChanged(fallbackHours: Int)
}

/// The six states of the offer screen, as one value. They replace each other in
/// place — no navigation, one grid — so the screen renders this and nothing else.
enum OfferState: Equatable, Hashable, Sendable {
    /// S1 — the offer itself.
    case offer
    /// S2 — a purchase is under way.
    case purchasing
    /// S3 — it did not go through. The reason picks the body; both bodies occupy the
    /// same pixels, and `cancelled` never lands here (the screen simply stays on S1).
    case failed(PurchaseFailure)
    /// S4 — waiting for approval (Ask to Buy).
    case awaitingApproval
    /// S5 — the entitlement has not been checked yet. Restore is the primary action.
    /// A pre-check state, not a failure: most people who see it never bought anything.
    case unverified
    /// S6 — the right is in hand. One frame for all three sources; the source picks
    /// the title and the body and nothing else, which is why there is no seventh
    /// state for a purchase to land on.
    case granted(EntitlementSource)
}
