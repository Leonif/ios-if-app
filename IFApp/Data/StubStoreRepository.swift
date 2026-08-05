//
//  StubStoreRepository.swift
//  IFApp
//
//  A store that answers from launch arguments instead of from Apple. DEBUG-only, and
//  registered only when `-seedStore` is present, so a normal build has no path to it.
//
//  It exists because the six states of the offer screen are otherwise unreachable
//  without a driver: StoreKit's local testing configuration is attached to the Xcode
//  scheme, and a simulator launched by `simctl` — which is how every Maestro flow and
//  every screenshot run starts the app — never sees it. Without this, the whole paid
//  surface can only be looked at by a human pressing Run.
//
//  It fakes the store's answers and nothing else: entitlement, price and outcome all
//  come straight from the arguments, and every verdict still travels the same actions
//  through the same reducer as the real one.
//

#if DEBUG
import Foundation

struct StubStoreRepository: StoreRepositoryProtocol {
    enum Argument {
        /// `-seedStore free|pro|unknown|missing` — what the store answers about this
        /// install. `missing` stands for an identifier the store does not know.
        static let store = "-seedStore"
        /// `-seedStorePrice "COP 29.900,00"` — deliberately awkward by default, so a
        /// layout that only survives `$6.99` is caught here rather than in Colombia.
        static let price = "-seedStorePrice"
        /// `-seedStoreOutcome purchased|pending|cancelled|network|other` — how the
        /// next Buy ends.
        static let outcome = "-seedStoreOutcome"
        /// `-seedStoreRestore restored|nothing|network|other`.
        static let restore = "-seedStoreRestore"
        /// `-seedStoreRevokeAfter N` — seconds until the entitlement is taken away,
        /// the way a refund or a departure from Family Sharing arrives. Edge 6 and
        /// edge 17 have no other door: both hang off an update nobody asked for.
        static let revokeAfter = "-seedStoreRevokeAfter"
    }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(Argument.store)
    }

    private static func value(_ name: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    func refresh() async -> (entitlement: Entitlement, product: ProProductInfo?) {
        let answer = Self.value(Argument.store) ?? "free"
        // `missing` is a verified free — the identifier is our configuration, not the
        // user's entitlement — but it leaves the screen with no price, which is the
        // whole point of being able to seed it.
        guard answer != "missing" else { return (.free, nil) }
        let entitlement = Entitlement(rawValue: answer) ?? .free
        return (entitlement, entitlement == .unknown ? nil : product)
    }

    func purchase() async -> PurchaseOutcome {
        switch Self.value(Argument.outcome) ?? "purchased" {
        case "pending": return .pending
        case "cancelled": return .cancelled
        case "network": return .failed(.network)
        case "other": return .failed(.other)
        default: return .purchased
        }
    }

    func restore() async -> RestoreOutcome {
        switch Self.value(Argument.restore) ?? "restored" {
        case "nothing": return .nothingToRestore
        case "network": return .failed(.network)
        case "other": return .failed(.other)
        default: return .restored
        }
    }

    /// One scripted revocation, or nothing at all.
    func entitlementUpdates() -> AsyncStream<Entitlement> {
        guard let seconds = Self.value(Argument.revokeAfter).flatMap(Double.init) else {
            return AsyncStream { $0.finish() }
        }
        return AsyncStream { continuation in
            let task = Task {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                continuation.yield(.free)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private var product: ProProductInfo {
        ProProductInfo(id: ProCatalog.productID,
                       displayPrice: Self.value(Argument.price) ?? "COP 29.900,00")
    }
}
#endif
