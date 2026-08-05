//
//  StoreRepository.swift
//  IFApp
//
//  The whole of StoreKit 2 for this app: one non-consumable, its price, buying it,
//  restoring it, and being told when it goes away. Everything above this file speaks
//  in `Entitlement` and outcomes and never imports StoreKit.
//
//  Verification is deliberately three-valued. `Transaction.currentEntitlements` never
//  throws and returns nothing both when the user did not buy and when this install has
//  not yet reached the store — a fresh install in airplane mode. Collapsing those two
//  into "free" is how an app tells a paying customer their purchase is gone, so the
//  store is probed separately and "we could not check" is reported as such.
//

import Foundation
import StoreKit

enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    /// Ask to Buy — approval pending, no entitlement yet.
    case pending
    case cancelled
    case failed(PurchaseFailure)
}

enum RestoreOutcome: Equatable, Sendable {
    case restored
    case nothingToRestore
    case failed(PurchaseFailure)
}

protocol StoreRepositoryProtocol {
    /// Resolves what this install owns and what the product costs, in one pass.
    func refresh() async -> (entitlement: Entitlement, product: ProProductInfo?)
    func purchase() async -> PurchaseOutcome
    /// Syncs with the App Store account and re-reads the entitlement. This is the
    /// only path that works with no account of ours, on a new device — an Apple
    /// review requirement for a non-consumable, not just a convenience.
    func restore() async -> RestoreOutcome
    /// Entitlement changes that happen without us asking: an approved Ask to Buy, a
    /// purchase made on another device, a refund, leaving a Family Sharing group.
    func entitlementUpdates() -> AsyncStream<Entitlement>
}

struct StoreRepository: StoreRepositoryProtocol {
    private enum Key {
        /// The last *verified* verdict. Its absence is meaningful: it means this
        /// install has never had an answer from the store, which is the only
        /// condition under which the entitlement is reported as unknown.
        static let verifiedEntitlement = "pro_entitlement_verified"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: Reading the entitlement

    func refresh() async -> (entitlement: Entitlement, product: ProProductInfo?) {
        let lookup = await lookUpProduct()

        if await ownsPro() {
            remember(true)
            return (.pro, lookup.info)
        }

        switch lookup {
        case .found, .missing:
            // The store answered. An empty entitlement set is then the truth about
            // this install, whatever we may have cached before — this is also how a
            // refund or a family member's departure settles.
            remember(false)
            return (.free, lookup.info)
        case .unreachable:
            // No answer. A previously verified verdict stands: a purchase already
            // seen on this device must survive a flight, and one already known to be
            // absent does not need re-proving to show the offer.
            guard let remembered = rememberedVerdict() else { return (.unknown, nil) }
            return (remembered ? .pro : .free, nil)
        }
    }

    /// True when a non-revoked transaction for the product is on this device.
    private func ownsPro() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result,
                  transaction.productID == ProCatalog.productID,
                  transaction.revocationDate == nil
            else { continue }
            return true
        }
        return false
    }

    private func rememberedVerdict() -> Bool? {
        defaults.object(forKey: Key.verifiedEntitlement) as? Bool
    }

    private func remember(_ isPro: Bool) {
        defaults.set(isPro, forKey: Key.verifiedEntitlement)
    }

    // MARK: Buying

    func purchase() async -> PurchaseOutcome {
        let lookup = await lookUpProduct()
        switch lookup {
        case .unreachable: return .failed(.network)
        case .missing: return .failed(.other)
        case let .found(product, _):
            do {
                switch try await product.purchase() {
                case let .success(verification):
                    guard case let .verified(transaction) = verification else {
                        return .failed(.other)
                    }
                    await transaction.finish()
                    remember(true)
                    return .purchased
                case .pending:
                    return .pending
                case .userCancelled:
                    return .cancelled
                @unknown default:
                    return .failed(.other)
                }
            } catch {
                return .failed(Self.reason(for: error))
            }
        }
    }

    func restore() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
        } catch {
            // Backing out of the App Store sign-in comes back as `cancelled`, which
            // the reducer treats as "nothing happened" rather than as an error.
            return .failed(Self.reason(for: error))
        }
        let owned = await ownsPro()
        remember(owned)
        return owned ? .restored : .nothingToRestore
    }

    // MARK: Listening

    func entitlementUpdates() -> AsyncStream<Entitlement> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    guard case let .verified(transaction) = update else { continue }
                    await transaction.finish()
                    // Re-read rather than trust the single transaction: a revocation
                    // and a purchase arrive through the same door, and only the full
                    // set says which side the user ends up on.
                    let owned = await ownsPro()
                    remember(owned)
                    continuation.yield(owned ? .pro : .free)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: Product lookup

    private enum ProductLookup {
        case found(Product, ProProductInfo)
        /// The store answered, and does not know this identifier — a configuration
        /// mistake on our side, not the user's connection.
        case missing
        case unreachable

        var info: ProProductInfo? {
            if case let .found(_, info) = self { return info }
            return nil
        }
    }

    private func lookUpProduct() async -> ProductLookup {
        do {
            guard let product = try await Product.products(for: [ProCatalog.productID]).first else {
                return .missing
            }
            return .found(product, ProProductInfo(id: product.id, displayPrice: product.displayPrice))
        } catch {
            return .unreachable
        }
    }

    /// Maps a StoreKit throw onto the three reasons the offer screen can act on.
    /// Only `network` changes what the user is told; the rest share one body.
    private static func reason(for error: Error) -> PurchaseFailure {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .networkError, .notAvailableInStorefront: return .network
            case .userCancelled: return .cancelled
            default: return .other
            }
        }
        if error is URLError { return .network }
        return .other
    }
}
