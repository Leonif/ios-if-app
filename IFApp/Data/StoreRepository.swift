//
//  StoreRepository.swift
//  IFApp
//

import Foundation
import StoreKit

struct StoreRepository: StoreRepositoryProtocol {
    private enum Key {
        static let verifiedEntitlement = "pro_entitlement_verified"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Reading the entitlement

    func refresh() async -> (entitlement: Entitlement, product: ProProductInfo?) {
        let lookup = await lookUpProduct()

        if await ownsPro() {
            remember(true)
            return (.pro, lookup.info)
        }

        switch lookup {
        case .found, .missing:
            remember(false)
            return (.free, lookup.info)
        case .unreachable:
            guard let remembered = rememberedVerdict() else { return (.unknown, nil) }
            return (remembered ? .pro : .free, nil)
        }
    }

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

    // MARK: - Buying

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
            return .failed(Self.reason(for: error))
        }
        let owned = await ownsPro()
        remember(owned)
        return owned ? .restored : .nothingToRestore
    }

    // MARK: - Listening

    func entitlementUpdates() -> AsyncStream<Entitlement> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    guard case let .verified(transaction) = update else { continue }
                    await transaction.finish()
                    let owned = await ownsPro()
                    remember(owned)
                    continuation.yield(owned ? .pro : .free)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Product lookup

    private enum ProductLookup {
        case found(Product, ProProductInfo)
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
