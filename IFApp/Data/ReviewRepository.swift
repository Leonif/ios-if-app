//
//  ReviewRepository.swift
//  IFApp
//
//  Native review-request persistence + the StoreKit call itself. ReviewMiddleware
//  gates every call (lifetime cap, 1/day, 1/launch) and owns the triggers; this
//  repo just remembers the gate state and the pending "next open" fallback.
//

import StoreKit
import UIKit

protocol ReviewRepositoryProtocol {
    /// True if requestReview may be called: not shown today and under the lifetime cap.
    func canPrompt() -> Bool
    /// Records a requestReview call (once per day, and counts toward the cap).
    func markPromptShown()
    /// Calls the native StoreKit review request and reports whether the call went out.
    ///
    /// `true` only when a `foregroundActive` scene was found and `AppStore.requestReview`
    /// was actually called — Apple still decides whether the panel appears. `false` means
    /// nothing was asked, and the caller must not spend an attempt on it.
    func requestReview(completion: @escaping (Bool) -> Void)
    /// The moment of the 3rd completed goal, when the "next open" fallback is armed.
    func pendingGoalDate() -> Date?
    func setPendingGoal(_ date: Date)
    func clearPendingGoal()
}

struct ReviewRepository: ReviewRepositoryProtocol {
    private let defaults: UserDefaults
    private enum Key {
        static let lastShown = "review_last_shown"
        static let promptCount = "review_prompt_count"
        static let pendingGoalAt = "review_pending_goal_at"
    }
    /// Lifetime cap on requestReview calls — Apple's own 3/365 limit is opaque, so
    /// we stop asking ourselves after this many attempts.
    private let maxPrompts = 3

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func canPrompt() -> Bool {
        if defaults.integer(forKey: Key.promptCount) >= maxPrompts { return false }
        if let last = defaults.object(forKey: Key.lastShown) as? Date,
           Calendar.current.isDateInToday(last) { return false }
        return true
    }

    func markPromptShown() {
        defaults.set(Date(), forKey: Key.lastShown)
        defaults.set(defaults.integer(forKey: Key.promptCount) + 1, forKey: Key.promptCount)
    }

    func requestReview(completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            // Only a `foregroundActive` scene counts. A request made on a scene that is
            // still `foregroundInactive` — which is exactly where a cold start sits when
            // the "next open" fallback fires — is dropped by Apple without a trace, and
            // falling back to `scenes.first` used to spend a lifetime attempt on it.
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
            else {
                completion(false)
                return
            }
            AppStore.requestReview(in: scene)
            completion(true)
        }
    }

    func pendingGoalDate() -> Date? {
        defaults.object(forKey: Key.pendingGoalAt) as? Date
    }

    func setPendingGoal(_ date: Date) {
        defaults.set(date, forKey: Key.pendingGoalAt)
    }

    func clearPendingGoal() {
        defaults.removeObject(forKey: Key.pendingGoalAt)
    }
}
