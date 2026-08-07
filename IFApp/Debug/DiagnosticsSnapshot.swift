//
//  DiagnosticsSnapshot.swift
//  IFApp
//
//  What the app believes about itself right now: which build, which App Store
//  environment, which storefront, and what the store says the product costs.
//
//  This exists because the journal answers "what happened" and this answers "where".
//  The two questions come up together — a price that looks wrong is not a bug until
//  you know which storefront produced it, and StoreKit's own view of the storefront
//  is the only thing that separates a real mismatch from a TestFlight artefact.
//
//  Reads StoreKit directly rather than through the store: these are facts about the
//  environment, not app state, and putting diagnostic-only actions through the reducer
//  would grow the product state machine to serve a debug screen.
//
//  Compiled out entirely outside DEBUG and DEVELOPMENT.
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

        // The whole point of the screen. `countryCode` is ISO-3: UKR, USA, ITA.
        if let storefront = await Storefront.current {
            items.append(Item(label: "storefront", value: storefront.countryCode))
            items.append(Item(label: "storefront id", value: storefront.id))
        } else {
            items.append(Item(label: "storefront", value: "nil — store unreachable"))
        }

        // Deliberately alongside the storefront: the device region and the storefront
        // disagreeing is itself the answer to most "wrong price" questions.
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

    /// `.xcode` means a local StoreKit configuration is in play and every price on this
    /// screen is fiction. `.sandbox` covers both TestFlight and App Review.
    private static func environment() async -> String {
        guard let result = try? await AppTransaction.shared else { return "unavailable" }
        guard case let .verified(transaction) = result else { return "unverified" }
        return transaction.environment.rawValue
    }

    /// The plain-text form, for the clipboard and the share sheet.
    static func text(_ items: [Item]) -> String {
        items.map { "\($0.label.padding(toLength: 14, withPad: " ", startingAt: 0)) \($0.value)" }
            .joined(separator: "\n")
    }
}

#endif
