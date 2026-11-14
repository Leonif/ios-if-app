//
//  StubStoreRepository.swift
//  IFApp
//

#if DEBUG
import Foundation

struct StubStoreRepository: StoreRepositoryProtocol {
    enum Argument {
        static let store = "-seedStore"
        static let price = "-seedStorePrice"
        static let outcome = "-seedStoreOutcome"
        static let restore = "-seedStoreRestore"
        static let restoreDelay = "-seedStoreRestoreDelay"
        static let purchaseDelay = "-seedStorePurchaseDelay"
        static let revokeAfter = "-seedStoreRevokeAfter"
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

    func entitlementUpdates() -> AsyncStream<Entitlement> {
        var scheduled: [(at: Double, entitlement: Entitlement)] = []
        if let s = Self.value(Argument.grantAfter).flatMap(Double.init) {
            scheduled.append((s, .pro))
        }
        if let s = Self.value(Argument.revokeAfter).flatMap(Double.init) {
            scheduled.append((s, .free))
        }
        guard !scheduled.isEmpty else { return AsyncStream { $0.finish() } }
        scheduled = scheduled.enumerated()
            .sorted { ($0.element.at, $0.offset) < ($1.element.at, $1.offset) }
            .map(\.element)

        return AsyncStream { continuation in
            let task = Task {
                var elapsed: Double = 0
                for step in scheduled {
                    try? await Task.sleep(nanoseconds: UInt64(max(0, step.at - elapsed) * 1_000_000_000))
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
