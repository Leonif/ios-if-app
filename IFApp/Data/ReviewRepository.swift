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
    /// True if the pre-prompt may show: not already reviewed, and not shown today.
    func canPrompt() -> Bool
    /// Records that the pre-prompt was shown (limits it to once per day).
    func markPromptShown()
    /// Opens the App Store write-review form and marks the user as reviewed.
    func openWriteReview()
}

struct ReviewRepository: ReviewRepositoryProtocol {
    private let defaults: UserDefaults
    private enum Key {
        static let lastShown = "review_last_shown"
        static let left = "review_left"
    }
    // ?action=write-review opens the review composer directly, not the product page.
    private let writeReviewURL = "https://apps.apple.com/app/id6738324344?action=write-review"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func canPrompt() -> Bool {
        if defaults.bool(forKey: Key.left) { return false }
        if let last = defaults.object(forKey: Key.lastShown) as? Date,
           Calendar.current.isDateInToday(last) { return false }
        return true
    }

    func markPromptShown() {
        defaults.set(Date(), forKey: Key.lastShown)
    }

    func openWriteReview() {
        defaults.set(true, forKey: Key.left)   // positive tap only — never prompt again
        guard let url = URL(string: writeReviewURL) else { return }
        Task { @MainActor in UIApplication.shared.open(url) }
    }
}
