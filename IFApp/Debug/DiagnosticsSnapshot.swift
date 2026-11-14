//
//  DiagnosticsSnapshot.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT

import Foundation
import StoreKit

enum DiagnosticsSnapshot {
    struct Item: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    static func collect() async -> [Item] {
        var items: [Item] = []

        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        items.append(Item(label: "build", value: "\(version) (\(build))"))
        items.append(Item(label: "bundle id", value: Bundle.main.bundleIdentifier ?? "?"))
        items.append(Item(label: "environment", value: await environment()))

        if let storefront = await Storefront.current {
            items.append(Item(label: "storefront", value: storefront.countryCode))
            items.append(Item(label: "storefront id", value: storefront.id))
        } else {
            items.append(Item(label: "storefront", value: "nil — store unreachable"))
        }

        items.append(Item(label: "device region", value: Locale.current.region?.identifier ?? "?"))

        let products = (try? await Product.products(for: [ProCatalog.productID])) ?? []
        if let product = products.first {
            items.append(Item(label: "product", value: product.id))
            items.append(Item(label: "displayPrice", value: product.displayPrice))
            items.append(Item(label: "price", value: "\(product.price)"))
            let locale = product.priceFormatStyle.locale
            items.append(Item(label: "currency", value: locale.currency?.identifier ?? "?"))
            items.append(Item(label: "price locale", value: locale.identifier))
        } else {
            items.append(Item(label: "product", value: "not found — \(ProCatalog.productID)"))
        }

        return items
    }

    private static func environment() async -> String {
        guard let result = try? await AppTransaction.shared else { return "unavailable" }
        guard case let .verified(transaction) = result else { return "unverified" }
        return transaction.environment.rawValue
    }

    static func text(_ items: [Item]) -> String {
        items.map { "\($0.label.padding(toLength: 14, withPad: " ", startingAt: 0)) \($0.value)" }
            .joined(separator: "\n")
    }
}

#endif
