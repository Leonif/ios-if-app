//
//  ProReducerTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class ProReducerTests: XCTestCase {

    private let product = ProProductInfo(id: ProCatalog.productID, displayPrice: "$6.99")

    private func openOffer(entitlement: Entitlement = .free,
                           phase: PurchasePhase = .idle) -> ProState {
        var state = ProState()
        state.entitlement = entitlement
        state.product = product
        state.phase = phase
        state.trigger = .manual
        return state
    }

    // MARK: - The right arrives

    func testApprovedAskToBuyConfirmsInsteadOfClosing() {
        let state = openOffer(phase: .awaitingApproval)

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertEqual(next.entitlement, .pro)
        XCTAssertEqual(next.phase, .granted(.approved))
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .granted(.approved))
    }

    func testEntitlementGrantedWhileReadingTheOfferClosesIt() {
        let state = openOffer()

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertFalse(next.isOfferOpen)
    }

    func testStoreResolvingProClosesAnOpenOffer() {
        var state = openOffer(entitlement: .unknown)
        state.product = nil
        XCTAssertEqual(state.offerState, .unverified)

        let next = proReducer(state: state,
                              action: ProAction.storeResolved(entitlement: .pro, product: product))

        XCTAssertFalse(next.isOfferOpen)
    }

    func testPurchaseCompletedConfirmsInsteadOfClosing() {
        let state = openOffer()

        let next = proReducer(state: state, action: ProAction.purchaseCompleted)

        XCTAssertEqual(next.entitlement, .pro)
        XCTAssertEqual(next.phase, .granted(.purchased))
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .granted(.purchased))
    }

    func testClosingTheConfirmationLeavesNothingBehind() {
        var state = openOffer()
        state = proReducer(state: state, action: ProAction.purchaseCompleted)

        let next = proReducer(state: state, action: ProAction.offerClosed)

        XCTAssertEqual(next.phase, .idle)
        XCTAssertFalse(next.isOfferOpen)
    }

    // MARK: - An attempt still has something to say

    func testRestoreCompletedKeepsTheOfferForItsConfirmation() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.restoreCompleted)

        XCTAssertEqual(next.entitlement, .pro)
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .granted(.restored))
    }

    func testEntitlementArrivingMidPurchaseKeepsTheOfferOpen() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .purchasing)
    }

    func testPendingApprovalKeepsTheOfferOpen() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.purchasePending)

        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .awaitingApproval)
    }

    func testEntitlementArrivingOverAFailureKeepsTheOfferOpen() {
        let state = openOffer(phase: .failed(.network))

        let next = proReducer(state: state, action: ProAction.entitlementChanged(.pro))

        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .failed(.network))
    }

    // MARK: - Nothing else moved

    func testCancelledPurchaseLeavesTheOfferStanding() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.purchaseFailed(.cancelled))

        XCTAssertEqual(next.entitlement, .free)
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .offer)
    }

    func testEmptyRestoreLeavesTheOfferStanding() {
        let state = openOffer(phase: .purchasing)

        let next = proReducer(state: state, action: ProAction.restoreFoundNothing)

        XCTAssertEqual(next.entitlement, .free)
        XCTAssertTrue(next.isOfferOpen)
        XCTAssertEqual(next.offerState, .offer)
        XCTAssertTrue(next.showsNothingToRestore)
    }

    // MARK: - T1' — the quality threshold

    func testHalfTheGoalIsTheThreshold() {
        let goal = 16.0

        XCTAssertFalse(OfferQualification.qualifies(elapsed: 7 * 3600 + 3599, goalHours: goal))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 8 * 3600, goalHours: goal))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 9 * 3600, goalHours: goal))
    }

    func testAFastAbandonedEarlyDoesNotQualify() {
        XCTAssertFalse(OfferQualification.qualifies(elapsed: 60, goalHours: 16))
    }

    func testReachingTheGoalQualifies() {
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 16 * 3600, goalHours: 16))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 21 * 3600, goalHours: 16))
    }

    func testTheThresholdFollowsTheGoalTheFastActuallyRanTo() {
        XCTAssertFalse(OfferQualification.qualifies(elapsed: 89 * 60, goalHours: 3))
        XCTAssertTrue(OfferQualification.qualifies(elapsed: 90 * 60, goalHours: 3))
    }

    func testAnUnpinnedGoalDoesNotQualify() {
        XCTAssertFalse(OfferQualification.qualifies(elapsed: 20 * 3600, goalHours: 0))
    }

    // MARK: - T1' — the one-time flag

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

    func testAnInstallThatHasHadItsOfferNeverArmsAgain() {
        var state = ProState(entitlement: .free, product: product)
        state.autoOfferShown = true

        let next = proReducer(state: state, action: ProAction.autoOfferArmed)

        XCTAssertFalse(next.autoOfferArmed)
        XCTAssertFalse(next.autoOfferPending)
    }

    func testShowingTheOfferSpendsTheFlag() {
        let next = proReducer(state: armed(),
                              action: ProAction.offerOpened(trigger: .fastFinished))

        XCTAssertTrue(next.autoOfferShown)
        XCTAssertFalse(next.autoOfferArmed)
        XCTAssertTrue(next.isOfferOpen)
    }

    func testTheOtherDoorsDoNotSpendTheFlag() {
        for trigger in [PaywallTrigger.planCustom, .manual, .streakBreak] {
            let next = proReducer(state: armed(),
                                  action: ProAction.offerOpened(trigger: trigger))

            XCTAssertFalse(next.autoOfferShown, "\(trigger) spent the one-time flag")
            XCTAssertTrue(next.autoOfferArmed, "\(trigger) disarmed the pending show")
        }
    }

    func testDismissDoesNotBringTheOfferBack() {
        let shown = proReducer(state: armed(),
                               action: ProAction.offerOpened(trigger: .fastFinished))

        let dismissed = proReducer(state: shown, action: ProAction.offerClosed)

        XCTAssertTrue(dismissed.autoOfferShown)
        XCTAssertFalse(dismissed.autoOfferPending)
        let laterFast = proReducer(state: dismissed, action: ProAction.autoOfferArmed)
        XCTAssertFalse(laterFast.autoOfferPending)
    }

    // MARK: - T1' — suppressions, none of which spend the flag

    func testCancellingAnArmedShowLeavesTheFlagWhole() {
        let next = proReducer(state: armed(), action: ProAction.autoOfferCancelled)

        XCTAssertFalse(next.autoOfferArmed)
        XCTAssertFalse(next.autoOfferShown)
        let rearmed = proReducer(state: next, action: ProAction.autoOfferArmed)
        XCTAssertTrue(rearmed.autoOfferPending)
    }

    func testAReviewPromptSuppressesTheOfferWithoutSpendingIt() {
        let next = proReducer(state: armed(),
                              action: AppLifecycleAction.reviewPrompted(trigger: .fastCompleted))

        XCTAssertTrue(next.reviewPromptedThisSession)
        XCTAssertFalse(next.autoOfferPending)
        XCTAssertTrue(next.autoOfferArmed)
        XCTAssertFalse(next.autoOfferShown)
    }

    func testAnUnverifiedEntitlementSuppressesTheOffer() {
        var state = armed()
        state.entitlement = .unknown

        XCTAssertFalse(state.autoOfferPending)
        XCTAssertFalse(state.autoOfferShown)
    }

    func testAMissingProductSuppressesTheOffer() {
        var state = armed()
        state.product = nil

        XCTAssertFalse(state.autoOfferPending)
        XCTAssertFalse(state.autoOfferShown)
    }

    func testAnOwnerHasNoPendingOffer() {
        var state = armed()
        state.entitlement = .pro

        XCTAssertFalse(state.autoOfferPending)
    }

    func testAnAttemptInFlightSuppressesTheOffer() {
        var state = armed()
        state.phase = .awaitingApproval

        XCTAssertFalse(state.autoOfferPending)
        XCTAssertFalse(state.autoOfferShown)
    }
}
