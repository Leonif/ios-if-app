//
//  ReviewRepository.swift
//  IFApp
//

import StoreKit
import UIKit

struct ReviewRepository: ReviewRepositoryProtocol {
    private let defaults: UserDefaults
    private enum Key {
        static let lastShown = "review_last_shown"
        static let promptCount = "review_prompt_count"
        static let legacyPendingGoalAt = "review_pending_goal_at"
    }
    private let maxPrompts = 3

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.removeObject(forKey: Key.legacyPendingGoalAt)
    }

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
}
