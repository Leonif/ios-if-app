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
        /// `-seedStoreRestoreDelay N` — milliseconds the next Restore spends in flight.
        /// Same reason as `purchaseDelay`: `restoreStarted` puts the screen in S2, and
        /// a stub that answers synchronously never lets that frame render, so the
        /// spinner on the Restore path cannot be observed at all. Default 0.
        static let restoreDelay = "-seedStoreRestoreDelay"
        /// `-seedStorePurchaseDelay N` — milliseconds the next Buy spends in flight
        /// before it resolves. Default 0, so existing flows keep the instant answer
        /// they were written against. Apple's sheet takes real time and `.purchasing`
        /// renders while it is up; a stub that answers synchronously never lets that
        /// phase reach the screen, and the spinner cannot be observed at all.
        static let purchaseDelay = "-seedStorePurchaseDelay"
        /// `-seedStoreRevokeAfter N` — seconds until the entitlement is taken away,
        /// the way a refund or a departure from Family Sharing arrives. Edge 6 and
        /// edge 17 have no other door: both hang off an update nobody asked for.
        static let revokeAfter = "-seedStoreRevokeAfter"
        /// `-seedStoreGrantAfter N` — seconds until the entitlement *arrives* through
        /// the same unasked-for door. Pairs with `-seedStoreOutcome pending`: that
        /// argument reaches S4 and stops there, but Ask to Buy is only half told by
        /// the wait — the half that matters is the approval landing later, with no
        /// relaunch, through `Transaction.updates`. Reproducing that for real needs a
        /// second Apple Account, a family organiser and someone to press Approve, so
        /// without this argument the transition out of S4 is unreachable locally.
        static let grantAfter = "-seedStoreGrantAfter"
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
        if let ms = Self.value(Argument.purchaseDelay).flatMap(UInt64.init), ms > 0 {
            try? await Task.sleep(nanoseconds: ms * 1_000_000)
        }
        switch Self.value(Argument.outcome) ?? "purchased" {
        case "pending": return .pending
        case "cancelled": return .cancelled
        case "network": return .failed(.network)
        case "other": return .failed(.other)
        default: return .purchased
        }
    }

    func restore() async -> RestoreOutcome {
        if let ms = Self.value(Argument.restoreDelay).flatMap(UInt64.init), ms > 0 {
            try? await Task.sleep(nanoseconds: ms * 1_000_000)
        }
        switch Self.value(Argument.restore) ?? "restored" {
        case "nothing": return .nothingToRestore
        case "network": return .failed(.network)
        case "other": return .failed(.other)
        default: return .restored
        }
    }

    /// The scripted unasked-for changes, in the order their seconds put them, or
    /// nothing at all. Both offsets are counted from launch, not from each other, so
    /// `-seedStoreGrantAfter 2 -seedStoreRevokeAfter 5` means what it reads like: Pro
    /// at two seconds, gone at five.
    func entitlementUpdates() -> AsyncStream<Entitlement> {
        var scheduled: [(at: Double, entitlement: Entitlement)] = []
        if let s = Self.value(Argument.grantAfter).flatMap(Double.init) {
            scheduled.append((s, .pro))
        }
        if let s = Self.value(Argument.revokeAfter).flatMap(Double.init) {
            scheduled.append((s, .free))
        }
        guard !scheduled.isEmpty else { return AsyncStream { $0.finish() } }
        // Ties resolve to the order the arguments are read above — `sort` is not
        // documented as stable, and equal offsets would otherwise pick a winner the
        // documented "in ascending order" does not promise.
        scheduled = scheduled.enumerated()
            .sorted { ($0.element.at, $0.offset) < ($1.element.at, $1.offset) }
            .map(\.element)

        return AsyncStream { continuation in
            let task = Task {
                var elapsed: Double = 0
                for step in scheduled {
                    try? await Task.sleep(nanoseconds: UInt64(max(0, step.at - elapsed) * 1_000_000_000))
                    // `try?` swallows the cancellation the sleep throws, so without
                    // this the whole schedule would fire back-to-back on teardown.
                    guard !Task.isCancelled else { break }
                    elapsed = step.at
                    continuation.yield(step.entitlement)
                }
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
