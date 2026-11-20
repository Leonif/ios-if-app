//
//  StoreMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class StoreMiddlewareTests: XCTestCase {
    private final class Box {
        var actions: [Action] = []
        var thunks: [Thunk] = []
    }

    private func recordingDispatch(into box: Box) -> DispatchFunction {
        DispatchFunction(dispatchAction: { box.actions.append($0) },
                         dispatchThunk: { box.thunks.append($0) })
    }

    func testLaunchStartsOneEntitlementSync() {
        let box = Box()
        StoreMiddleware().handle(action: AppLifecycleAction.appOpened, state: AppState(),
                                 dispatch: recordingDispatch(into: box))
        XCTAssertEqual(box.thunks.count, 1)
        XCTAssertTrue(box.thunks.first is SyncEntitlementThunk)
        XCTAssertTrue(box.actions.isEmpty)
    }

    func testBuyTapRunsThePurchase() {
        let box = Box()
        StoreMiddleware().handle(action: ProAction.purchaseTapped, state: AppState(),
                                 dispatch: recordingDispatch(into: box))
        XCTAssertEqual(box.thunks.count, 1)
        XCTAssertTrue(box.thunks.first is PurchaseProThunk)
        XCTAssertTrue(box.actions.isEmpty)
    }

    func testRestoreTapRunsTheRestore() {
        let box = Box()
        StoreMiddleware().handle(action: ProAction.restoreTapped, state: AppState(),
                                 dispatch: recordingDispatch(into: box))
        XCTAssertEqual(box.thunks.count, 1)
        XCTAssertTrue(box.thunks.first is RestorePurchasesThunk)
        XCTAssertTrue(box.actions.isEmpty)
    }

    func testTheAttemptsOwnActionsRunNothing() {
        let box = Box()
        let middleware = StoreMiddleware()
        for action in [ProAction.purchaseStarted, .purchaseCompleted, .restoreStarted, .restoreCompleted] {
            middleware.handle(action: action, state: AppState(), dispatch: recordingDispatch(into: box))
        }
        XCTAssertTrue(box.thunks.isEmpty)
    }
}
