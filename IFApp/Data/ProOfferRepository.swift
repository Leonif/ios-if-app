//
//  ProOfferRepository.swift
//  IFApp
//
//  The one fact about the offer that outlives a launch: whether the automatic,
//  once-in-the-life-of-an-install show (T1') has already happened.
//
//  Nothing else about the offer is persisted on purpose. The plan to show it belongs
//  to the session that finished the fast — see `ProState.autoOfferArmed` — so the
//  only thing worth carrying across launches is that the show is spent.
//

import Foundation

protocol ProOfferRepositoryProtocol {
    /// Whether the automatic offer has ever been shown on this install.
    func wasOfferShown() -> Bool
    /// Records that it has. Idempotent: it is written from the reduced state rather
    /// than from one action, so it lands again on every later Pro action and must not
    /// care.
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
