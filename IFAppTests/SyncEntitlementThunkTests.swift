//
//  SyncEntitlementThunkTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class SyncEntitlementThunkTests: XCTestCase {
    private struct Store: StoreRepositoryProtocol {
        let owned: Entitlement
        let changes: [Entitlement]
        func refresh() async -> (entitlement: Entitlement, product: ProProductInfo?) { (owned, nil) }
        func purchase() async -> PurchaseOutcome { .cancelled }
        func restore() async -> RestoreOutcome { .nothingToRestore }
        func entitlementUpdates() -> AsyncStream<Entitlement> {
            AsyncStream { continuation in
                changes.forEach { continuation.yield($0) }
                continuation.finish()
            }
        }
    }

    private enum Seen: Equatable {
        case resolved(Entitlement)
        case changed(Entitlement)
    }

    func testResolvesFirstThenFollowsEveryChange() async {
        var seen: [Seen] = []
        await SyncEntitlementThunk(store: Store(owned: .free, changes: [.pro, .free]))
            .execute(state: AppState(), dispatch: { action in
                switch action {
                case let ProAction.storeResolved(entitlement, _): seen.append(.resolved(entitlement))
                case let ProAction.entitlementChanged(entitlement): seen.append(.changed(entitlement))
                default: XCTFail("\(action)")
                }
            })
        XCTAssertEqual(seen, [.resolved(.free), .changed(.pro), .changed(.free)])
    }
}
