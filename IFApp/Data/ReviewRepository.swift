//
//  ReviewRepository.swift
//  IFApp
//
//  Rating pre-prompt persistence + the App Store review deep link. The custom
//  "Enjoying IF24?" sheet is shown before any review request (ReviewMiddleware
//  gates it); tapping the positive CTA opens the App Store write-review form.
//

import UIKit

protocol ReviewRepositoryProtocol {
    /// True if the pre-prompt may show: not already reviewed, not shown today,
    /// and under the lifetime show cap.
    func canPrompt() -> Bool
    /// Records that the pre-prompt was shown (once per day, and counts toward the cap).
    func markPromptShown()
    /// Opens the App Store write-review form and marks the user as reviewed.
    func openWriteReview()
}

struct ReviewRepository: ReviewRepositoryProtocol {
    private let defaults: UserDefaults
    private enum Key {
        static let lastShown = "review_last_shown"
        static let left = "review_left"
        static let promptCount = "review_prompt_count"
    }
    /// Lifetime cap on our own sheet — it isn't covered by Apple's native limit.
    private let maxPrompts = 3
    // ?action=write-review opens the review composer directly, not the product page.
    private let writeReviewURL = "https://apps.apple.com/app/id6738324344?action=write-review"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func canPrompt() -> Bool {
        if defaults.bool(forKey: Key.left) { return false }
        if defaults.integer(forKey: Key.promptCount) >= maxPrompts { return false }
        if let last = defaults.object(forKey: Key.lastShown) as? Date,
           Calendar.current.isDateInToday(last) { return false }
        return true
    }

    func markPromptShown() {
        defaults.set(Date(), forKey: Key.lastShown)
        defaults.set(defaults.integer(forKey: Key.promptCount) + 1, forKey: Key.promptCount)
    }

    func openWriteReview() {
        defaults.set(true, forKey: Key.left)   // positive tap only — never prompt again
        guard let url = URL(string: writeReviewURL) else { return }
        Task { @MainActor in UIApplication.shared.open(url) }
    }
}
