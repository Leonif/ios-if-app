//
//  ProReducerTests.swift
//  IFAppTests
//
//  The offer screen must never invite a purchase from someone who already owns Pro.
//  Found on the approved Ask to Buy path: the entitlement arrived, the reducer cleared
//  the purchase phase but not the entry point, and the screen fell back to S1 with a
//  live Buy button whose tap does nothing (`PurchaseProThunk` guards on `isPro`).
//
//  The right can arrive three ways, so the guard is one rule over the state rather
//  than three edits; these tests hold both halves of it — the offer closes once there
//  is nothing left to sell, and it stays up while an attempt still has something to
//  say.
//

import XCTest
import Redux
@testable import IFApp

final class ProReducerTests: XCTestCase {

    private let product = ProProductInfo(id: ProCatalog.productID, displayPrice: "$6.99")

    /// The offer up, opened from the About sheet, with a price behind it.
    private func openOffer(entitlement: Entitlement = .free,
                           phase: PurchasePhase = .idle) -> ProState {
        var state = ProState()
        state.entitlement = entitlement
        state.product = product
        state.phase = phase
        state.trigger = .manual
        return state
    }

    // MARK: The right arrives

    /// The defect itself. Ask to Buy is approved while the offer is still up: the
    /// screen has to leave S4, and it must not land on the offer.
    func testApprovedAskToBuyClosesTheOffer() {
        let state = openOffer(phase: .awaitingApproval)

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertEqual(next.entitlement, .pro)
        XCTAssertEqual(next.phase, .idle)
        XCTAssertFalse(next.isOfferOpen)
        // What the defect looked like, spelled out: the six-state value is about the
        // frame, not about whether the frame is up, so with the entry point still set
        // this state renders S1 — the Buy button, in front of the owner. Closing is
        // the whole fix, and `isOfferOpen` above is where it shows.
        XCTAssertEqual(next.offerState, .offer)
    }

    /// The same right arriving from another device or a family member's purchase,
    /// with the offer merely being read at the time.
    func testEntitlementGrantedWhileReadingTheOfferClosesIt() {
        let state = openOffer()

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertFalse(next.isOfferOpen)
    }

    /// The store answering late: the offer was opened at S5 because nothing had been
    /// checked yet, and the answer is that this install owns it.
    func testStoreResolvingProClosesAnOpenOffer() {
        var state = openOffer(entitlement: .unknown)
        state.product = nil
        XCTAssertEqual(state.offerState, .unverified)

        let next = proReducer(state: state,
                              action: ProAction.storeResolved(entitlement: .pro, product: product))

        XCTAssertFalse(next.isOfferOpen)
    }

    /// The path that already worked, and has to keep working now that it leans on the
    /// same rule instead of clearing the entry point itself.
    func testPurchaseCompletedClosesTheOffer() {
        let state = openOffer()

        let next = proReducer(state: state, action: ProAction.purchaseCompleted)

        XCTAssertEqual(next.entitlement, .pro)
        XCTAssertEqual(next.phase, .idle)
        XCTAssertFalse(next.isOfferOpen)
    }

    // MARK: An attempt still has something to say

    /// Restore keeps the screen: S6 is a confirmation the user has to see, and it is
    /// the restore flow that closes the offer afterwards.
    func testRestoreCompletedKeepsTheOfferForItsConfirmation() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.restoreCompleted)

        XCTAssertEqual(next.entitlement, .pro)
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .restored)
    }

    /// A transaction that reports the entitlement before it reports itself finished:
    /// the purchase is still settling, so S2 stays up until it does.
    func testEntitlementArrivingMidPurchaseKeepsTheOfferOpen() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .purchasing)
    }

    /// Ask to Buy without an answer yet: nothing has been granted, so there is
    /// nothing for the rule to act on and S4 stands.
    func testPendingApprovalKeepsTheOfferOpen() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.purchasePending)

        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .awaitingApproval)
    }

    /// The right arriving on top of an error the user is still reading. The failure
    /// was about an attempt, and S3 is the frame that says so — it gets to finish.
    func testEntitlementArrivingOverAFailureKeepsTheOfferOpen() {
        let state = openOffer(phase: .failed(.network))

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .failed(.network))
    }

    // MARK: Nothing else moved

    /// Backing out of Apple's sheet leaves the offer exactly as it was — the user is
    /// still free, and still looking at S1.
    func testCancelledPurchaseLeavesTheOfferStanding() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.purchaseFailed(.cancelled))

        XCTAssertEqual(next.entitlement, .free)
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .offer)
    }

    /// An empty restore settles the entitlement as `free`, which is not the right and
    /// does not close anything.
    func testEmptyRestoreLeavesTheOfferStanding() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.restoreFoundNothing)

        XCTAssertEqual(next.entitlement, .free)
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .offer)
        XCTAssertTrue(next.showsNothingToRestore)
    }

    // MARK: T1' — the quality threshold
    //
    // The filter and the one-time flag are the two pieces of the automatic trigger
    // that no screenshot can hold: both are invisible when they work, and both are the
    // kind of rule a later refactor breaks without anything going red. The offer is
    // shown once in the life of an install, so a regression here is not a bug someone
    // reports — it is an offer that silently never appears, or appears on the fast a
    // person abandoned after a minute.

    /// Half the goal, exactly as specified. The boundary is checked from both sides
    /// because "less than 50%" and "at least 50%" is the entire rule.
    func testHalfTheGoalIsTheThreshold() {
        let goal = 16.0

        XCTAssertFalse(OfferQualification.qualifies(elapsed: 7 * 3600 + 3599, goalHours: goal))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 8 * 3600, goalHours: goal))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 9 * 3600, goalHours: goal))
    }

    /// The fast people abandon in the first minutes — the case the filter exists for.
    func testAFastAbandonedEarlyDoesNotQualify() {
        XCTAssertFalse(OfferQualification.qualifies(elapsed: 60, goalHours: 16))
    }

    /// Reaching the goal needs no branch of its own; it is past the fraction already.
    /// Stated as a test so a future edit cannot "add the missing goal_reached case"
    /// and end up with two definitions of the same predicate.
    func testReachingTheGoalQualifies() {
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 16 * 3600, goalHours: 16))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 21 * 3600, goalHours: 16))
    }

    /// A custom goal is compared against itself, not against a preset: on a 3-hour
    /// goal the threshold is 90 minutes.
    func testTheThresholdFollowsTheGoalTheFastActuallyRanTo() {
        XCTAssertFalse(OfferQualification.qualifies(elapsed: 89 * 60, goalHours: 3))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 90 * 60, goalHours: 3))
    }

    /// No goal to measure against, no verdict. State written before the goal was
    /// pinned resolves to the plan upstream; a zero arriving here is not a fast that
    /// qualified by dividing by nothing.
    func testAnUnpinnedGoalDoesNotQualify() {
        XCTAssertFalse(OfferQualification.qualifies(elapsed: 20 * 3600, goalHours: 0))
    }

    // MARK: T1' — the one-time flag

    /// Free, verified, with a price behind it, and a qualified fast just ended.
    private func armed() -> ProState {
        var state = ProState()
        state.entitlement = .free
        state.product = product
        state.autoOfferArmed = true
        return state
    }

    func testArmingMakesTheShowPending() {
        let next = proReducer(state: ProState(entitlement: .free, product: product),
                              action: ProAction.autoOfferArmed)

        XCTAssertTrue(next.autoOfferArmed)
        XCTAssertTrue(next.autoOfferPending)
    }

    /// "Exactly once, ever" held at the earliest point: an install that has had its
    /// offer never arms another, so nothing later has to carry a plan that can never
    /// fire.
    func testAnInstallThatHasHadItsOfferNeverArmsAgain() {
        var state = ProState(entitlement: .free, product: product)
        state.autoOfferShown = true

        let next = proReducer(state: state, action: ProAction.autoOfferArmed)

        XCTAssertFalse(next.autoOfferArmed)
        XCTAssertFalse(next.autoOfferPending)
    }

    /// The flag is spent on the fact of a show and on nothing else.
    func testShowingTheOfferSpendsTheFlag() {
        let next = proReducer(state: armed(),
                              action: ProAction.offerOpened(trigger: .fastFinished))

        XCTAssertTrue(next.autoOfferShown)
        XCTAssertFalse(next.autoOfferArmed)
        XCTAssertTrue(next.isOfferOpen)
    }

    /// The other three doors are the user's own action and say nothing about the
    /// automatic one. Someone who opens the offer from the About sheet has not used up
    /// the show their next finished fast has coming.
    func testTheOtherDoorsDoNotSpendTheFlag() {
        for trigger in [PaywallTrigger.planCustom, .manual, .streakBreak] {
            let next = proReducer(state: armed(),
                                  action: ProAction.offerOpened(trigger: trigger))

            XCTAssertFalse(next.autoOfferShown, "\(trigger) spent the one-time flag")
            XCTAssertTrue(next.autoOfferArmed, "\(trigger) disarmed the pending show")
        }
    }

    /// Edge 11: after a dismiss it does not come back, this launch or any later one.
    func testDismissDoesNotBringTheOfferBack() {
        let shown = proReducer(state: armed(),
                               action: ProAction.offerOpened(trigger: .fastFinished))

        let dismissed = proReducer(state: shown, action: ProAction.offerClosed)

        XCTAssertTrue(dismissed.autoOfferShown)
        XCTAssertFalse(dismissed.autoOfferPending)
        // And a later fast cannot resurrect it.
        let laterFast = proReducer(state: dismissed, action: ProAction.autoOfferArmed)
        XCTAssertFalse(laterFast.autoOfferPending)
    }

    // MARK: T1' — suppressions, none of which spend the flag
    //
    // Each of these is the same bargain: the show moves to the next qualified fast and
    // the install keeps its one offer. The assertion that matters in every one is the
    // second — `autoOfferShown` still false.

    /// Edge 20: the fast is taken back, so the show armed for it goes too. This is
    /// what stands between a mis-tapped End fast at 60% of the goal and a lifetime
    /// offer spent on it.
    func testCancellingAnArmedShowLeavesTheFlagWhole() {
        let next = proReducer(state: armed(), action: ProAction.autoOfferCancelled)

        XCTAssertFalse(next.autoOfferArmed)
        XCTAssertFalse(next.autoOfferShown)
        // The next qualified fast arms normally.
        let rearmed = proReducer(state: next, action: ProAction.autoOfferArmed)
        XCTAssertTrue(rearmed.autoOfferPending)
    }

    /// The review prompt outranks the offer for the rest of the launch. `reviewPrompted`
    /// means the request was made — Apple may have shown nothing — which is exactly why
    /// suppressing on it has to be free.
    func testAReviewPromptSuppressesTheOfferWithoutSpendingIt() {
        let next = proReducer(state: armed(),
                              action: AppLifecycleAction.reviewPrompted(trigger: .streakMilestone))

        XCTAssertTrue(next.reviewPromptedThisSession)
        XCTAssertFalse(next.autoOfferPending)
        XCTAssertTrue(next.autoOfferArmed)
        XCTAssertFalse(next.autoOfferShown)
    }

    /// Edge 16 / PW-9: an entitlement nobody has been able to check yet gates like
    /// free, but the offer never opens on its own there — we do not invite a second
    /// purchase of something this install may already own.
    func testAnUnverifiedEntitlementSuppressesTheOffer() {
        var state = armed()
        state.entitlement = .unknown

        XCTAssertFalse(state.autoOfferPending)
        XCTAssertFalse(state.autoOfferShown)
    }

    /// No price, no offer: the screen is a frame built around one, and a store that
    /// did not answer cannot sell anything.
    func testAMissingProductSuppressesTheOffer() {
        var state = armed()
        state.product = nil

        XCTAssertFalse(state.autoOfferPending)
        XCTAssertFalse(state.autoOfferShown)
    }

    /// Edge 10: an owner is never shown any of the three automatic triggers.
    func testAnOwnerHasNoPendingOffer() {
        var state = armed()
        state.entitlement = .pro

        XCTAssertFalse(state.autoOfferPending)
    }

    /// An Ask to Buy still out with whoever approves it is an attempt in flight. The
    /// automatic offer does not interrupt it to sell the same thing again.
    func testAnAttemptInFlightSuppressesTheOffer() {
        var state = armed()
        state.phase = .awaitingApproval

        XCTAssertFalse(state.autoOfferPending)
        XCTAssertFalse(state.autoOfferShown)
    }
}
