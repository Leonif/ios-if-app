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
}
