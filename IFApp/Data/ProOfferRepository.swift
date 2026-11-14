//
//  ProOfferRepository.swift
//  IFApp
//

import Foundation

protocol ProOfferRepositoryProtocol {
    func wasOfferShown() -> Bool
    func markOfferShown()
}

struct ProOfferRepository: ProOfferRepositoryProtocol {
    private enum Key {
        static let offerShown = "pro_offer_shown"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func wasOfferShown() -> Bool {
        defaults.bool(forKey: Key.offerShown)
    }

    func markOfferShown() {
        defaults.set(true, forKey: Key.offerShown)
    }
}
