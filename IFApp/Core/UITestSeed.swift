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
        defaults.set(0, forKey: "streak_count")
        defaults.removeObject(forKey: "streak_last_goal_date")
        defaults.set(0, forKey: "streak_last_milestone_shown")
        defaults.removeObject(forKey: "plan_idx")          // fall back to Plan.default
        defaults.removeObject(forKey: "review_last_shown")
        defaults.set(0, forKey: "review_prompt_count")
        defaults.removeObject(forKey: "review_pending_goal_at")

        func intArg(_ name: String) -> Int? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return Int(args[i + 1])
        }

        if let sec = intArg("-seedElapsed") {
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "start_timestamp")
            defaults.set(true, forKey: "is_running")
        }
        if let sec = intArg("-seedEatingElapsed") {
            // Eating window opened N seconds ago (fast not running). N past the window
            // length lands on the window-closed (eatingOver) screen; N past the window
            // length + 24h falls through to idle — all derived from this one timestamp.
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "eating_start_timestamp")
            defaults.set(true, forKey: "is_eating")
            defaults.set(false, forKey: "is_running")
        }
        if let c = intArg("-seedCount") { defaults.set(c, forKey: "completed_sessions_count") }
        if let cel = intArg("-seedCelebrated") { defaults.set(cel == 1, forKey: "has_celebrated") }
        if let p = intArg("-seedPlan") { defaults.set(p, forKey: "plan_idx") }
        if let pc = intArg("-seedPromptCount") { defaults.set(pc, forKey: "review_prompt_count") }
        // Streak: "-seedStreak N" sets the counter; the last-goal day defaults to
        // today so the badge renders, "-seedLastGoalDate D" moves it D days back
        // (D=1 → yesterday, so crossing a goal extends the streak to N+1).
        if let s = intArg("-seedStreak") { defaults.set(s, forKey: "streak_count") }
        if intArg("-seedStreak") != nil || intArg("-seedLastGoalDate") != nil {
            let daysAgo = intArg("-seedLastGoalDate") ?? 0
            let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            defaults.set(Clock.dayKey(day), forKey: "streak_last_goal_date")
        }
    }
}
#endif
