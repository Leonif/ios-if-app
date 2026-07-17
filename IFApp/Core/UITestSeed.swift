//
//  UITestSeed.swift
//  IFApp
//
//  Seeds timer/review UserDefaults from launch arguments so UI tests reach
//  time-dependent screens (goal reached, overtime, review prompt) without waiting
//  16h or rebooting the simulator to defeat cfprefsd. Offset-based: `-seedElapsed N`
//  means "the fast started N seconds ago", resolved against the clock at launch, so
//  a static Maestro flow stays accurate. No-op unless a `-seed…` argument is present.
//  DEBUG-only — never compiled into release.
//

#if DEBUG
import Foundation

enum UITestSeed {
    /// Applies seed arguments to `defaults`. Any `-seed…` arg first wipes a clean
    /// baseline (timer + review), then the provided values override it, so an
    /// unspecified key never leaks state from a previous run.
    static func applyIfNeeded(_ defaults: UserDefaults = .standard) {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains(where: { $0.hasPrefix("-seed") }) else { return }

        // clean baseline
        defaults.set(0.0, forKey: "start_timestamp")
        defaults.set(false, forKey: "is_running")
        defaults.set(0, forKey: "completed_sessions_count")
        defaults.set(false, forKey: "has_celebrated")
        defaults.set(0.0, forKey: "eating_start_timestamp")
        defaults.set(false, forKey: "is_eating")
        defaults.removeObject(forKey: "plan_idx")          // fall back to Plan.default
        defaults.removeObject(forKey: "review_last_shown")
        defaults.set(false, forKey: "review_left")
        defaults.set(0, forKey: "review_prompt_count")

        func intArg(_ name: String) -> Int? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return Int(args[i + 1])
        }

        if let sec = intArg("-seedElapsed") {
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "start_timestamp")
            defaults.set(true, forKey: "is_running")
        }
        if let sec = intArg("-seedEatingElapsed") {
            // Eating window opened N seconds ago (fast not running).
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "eating_start_timestamp")
            defaults.set(true, forKey: "is_eating")
            defaults.set(false, forKey: "is_running")
        }
        if let c = intArg("-seedCount") { defaults.set(c, forKey: "completed_sessions_count") }
        if let cel = intArg("-seedCelebrated") { defaults.set(cel == 1, forKey: "has_celebrated") }
        if let p = intArg("-seedPlan") { defaults.set(p, forKey: "plan_idx") }
        if let pc = intArg("-seedPromptCount") { defaults.set(pc, forKey: "review_prompt_count") }
    }
}
#endif
