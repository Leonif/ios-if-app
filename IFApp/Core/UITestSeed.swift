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
        defaults.set(0.0, forKey: "goal_hours")
        defaults.set(false, forKey: "is_running")
        defaults.set(0, forKey: "completed_sessions_count")
        defaults.set(false, forKey: "has_celebrated")
        defaults.set(0.0, forKey: "eating_start_timestamp")
        defaults.set(false, forKey: "is_eating")
        defaults.set(0, forKey: "streak_count")
        defaults.removeObject(forKey: "streak_last_goal_date")
        defaults.removeObject(forKey: "streak_freeze_spent_month")
        defaults.set(0, forKey: "streak_last_milestone_shown")
        defaults.removeObject(forKey: "plan_hours")        // fall back to Plan.default
        defaults.removeObject(forKey: "plan_idx")          // pre-1.5.0 key, cleared too
        defaults.removeObject(forKey: "review_last_shown")
        defaults.set(0, forKey: "review_prompt_count")
        defaults.removeObject(forKey: "review_pending_goal_at")
        defaults.set(false, forKey: "pro_offer_shown")

        func intArg(_ name: String) -> Int? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return Int(args[i + 1])
        }

        if let sec = intArg("-seedElapsed") {
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "start_timestamp")
            defaults.set(true, forKey: "is_running")
            // A seeded fast is a fast in flight, so it carries a pinned goal like any
            // other. "-seedPlanHours" (below) may override it; without one it is the default
            // plan, which is what the seeded state would have started from.
            defaults.set(defaults.double(forKey: "goal_hours") > 0
                         ? defaults.double(forKey: "goal_hours")
                         : Double(Plan.default.hours), forKey: "goal_hours")
        }
        if let sec = intArg("-seedEatingElapsed") {
            // Eating window opened N seconds ago (fast not running). N past the window
            // length lands on the window-closed (eatingOver) screen; N past the window
            // length + 24h falls through to idle — all derived from this one timestamp.
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "eating_start_timestamp")
            defaults.set(true, forKey: "is_eating")
            defaults.set(false, forKey: "is_running")
            // The window's length belongs to the fast that opened it — same pinning.
            defaults.set(Double(Plan.default.hours), forKey: "goal_hours")
        }
        if let c = intArg("-seedCount") { defaults.set(c, forKey: "completed_sessions_count") }
        if let cel = intArg("-seedCelebrated") { defaults.set(cel == 1, forKey: "has_celebrated") }
        // "-seedPlanHours N": N is the plan's length in hours (14/16/18/20, or any
        // 1-23 custom goal). It also re-pins the goal of a seeded in-flight cycle,
        // which is what a fast started on that plan would carry.
        //
        // Renamed from "-seedPlan N", which took a position in the preset list. The
        // name changed on purpose rather than the meaning quietly: "-seedPlan 3" is
        // a valid *hours* value too, so a flow left unchanged would have seeded a
        // 3-hour plan and looked plausible. Unrecognised now, it seeds nothing and
        // the plan falls back to the default.
        if let p = intArg("-seedPlanHours"), Plan.range.contains(p) {
            defaults.set(p, forKey: "plan_hours")
            if defaults.bool(forKey: "is_running") || defaults.bool(forKey: "is_eating") {
                defaults.set(Double(p), forKey: "goal_hours")
            }
        }
        // "-seedGoalHours N": pins the running/eating fast's goal independently of
        // the plan. Applied last so it overrides whatever "-seedElapsed" or
        // "-seedPlanHours" set above — needed to seed a fast whose pinned goal
        // disagrees with the currently-selected plan (dev-task-1.5.0-hardening
        // B8: resume must restore the pinned goal, not the plan; without this arg
        // that scenario cannot be constructed at all, not merely by coincidence).
        if let g = intArg("-seedGoalHours") { defaults.set(Double(g), forKey: "goal_hours") }
        if let pc = intArg("-seedPromptCount") { defaults.set(pc, forKey: "review_prompt_count") }
        // "-seedOfferShown 1": the automatic offer (T1') has already been spent on
        // this install. The criterion it exists for — shown exactly once, ever, and
        // not again after a dismiss — otherwise needs two qualified fasts inside one
        // launch, and a launch cannot be re-seeded from inside itself.
        //
        // There is deliberately no argument for "armed but not yet shown": the plan
        // to show lives only in the session that finished the fast and is never
        // persisted, so a flow reaches it the way a user does — end a fast past the
        // quality threshold, then open the eating window.
        if let shown = intArg("-seedOfferShown") { defaults.set(shown == 1, forKey: "pro_offer_shown") }
        // "-seedPendingGoal N": the 3rd-goal review fallback was armed N seconds ago,
        // so the next open can reach the native request without driving three real
        // goals first. N past ReviewMiddleware's 4h delay makes the request due.
        if let sec = intArg("-seedPendingGoal") {
            defaults.set(Date().addingTimeInterval(-Double(sec)), forKey: "review_pending_goal_at")
        }
        // Streak: "-seedStreak N" sets the counter; the last-goal day defaults to
        // today so the badge renders, "-seedLastGoalDate D" moves it D days back
        // (D=1 → yesterday, so crossing a goal extends the streak to N+1).
        if let s = intArg("-seedStreak") { defaults.set(s, forKey: "streak_count") }
        if intArg("-seedStreak") != nil || intArg("-seedLastGoalDate") != nil {
            let daysAgo = intArg("-seedLastGoalDate") ?? 0
            let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            defaults.set(Clock.dayKey(day), forKey: "streak_last_goal_date")
        }
        // "-seedFreezeSpent 1": this calendar month's protected day is already used
        // up. The criterion it exists for — one freeze per calendar month — needs a
        // *second* missed day in one month, and a single launch cannot produce the
        // first one: spending a freeze takes a goal crossed on a day the flow has no
        // way to travel to. Without this argument the second-miss branch is reachable
        // from unit tests only.
        //
        // The month charged is the one the app itself would debit for the gap this
        // same seed describes — the month of the *missed* day, asked of
        // `StreakStatus.freezeMonthCharged(afterGoalOn:)` rather than recomputed here,
        // so a seed that charges a different month than the rule cannot exist.
        //
        // Not "the current month": on the 1st and 2nd those are two different months,
        // and seeding today's would leave the freeze unspent exactly then — a flow
        // green for 29 days of the month and red on the other two.
        //
        // When the seeded state has no gap at all (last goal today or yesterday) there
        // is nothing for a freeze to cover, and the plain reading of the argument is
        // today's month. The gap is checked explicitly instead of falling out of a nil:
        // "-seedStreak N" alone already writes today into `streak_last_goal_date`, so a
        // fallback keyed on "no last goal" would never run, and the month of *tomorrow*
        // would be charged — next month, on the 31st.
        if intArg("-seedFreezeSpent") == 1 {
            let today = Clock.dayKey()
            let gapMonth = defaults.string(forKey: "streak_last_goal_date").flatMap { goal -> String? in
                guard (Clock.daysBetween(goal, today) ?? 0) >= 2 else { return nil }
                return StreakStatus.freezeMonthCharged(afterGoalOn: goal)
            }
            defaults.set(gapMonth ?? Clock.monthKey(ofDay: today), forKey: "streak_freeze_spent_month")
        }

        // History lives in a file, not in defaults — wipe it alongside the baseline
        // so a previous run's records can't leak into this one.
        //
        // Through `wipeFile()` rather than `replaceAll([])`: `replaceAll` honours the
        // TF-2 write guard, so a file left `.readOnly` by an earlier flow's
        // "-seedHistoryFutureSchema" makes this wipe — and every "-seedHistory" below
        // it — a silent no-op for the rest of the suite. Same cast as the two seeders,
        // for the same reason.
        let history: FastHistoryRepositoryProtocol = container.inject()
        (history as? FastHistoryRepository)?.wipeFile()
        if args.contains("-seedHistoryCorrupt") {
            // Puts undecodable bytes where the history file goes, so the failed-decode
            // path can be walked from a flow or by hand. Goes through the concrete type
            // on purpose: the protocol only speaks in records, and a record that fails
            // to decode is not something it can express. The cast is total in practice —
            // `FastHistoryRepository` is the only conformance — and a miss seeds nothing
            // rather than pretending it did.
            (history as? FastHistoryRepository)?.seedCorruptFile()
        } else if args.contains("-seedHistoryFutureSchema") {
            // Same reasoning as "-seedHistoryCorrupt" above, for the sibling TF-2 path:
            // a well-formed envelope from a schema this build has not shipped (readOnly),
            // not an undecodable one (quarantine). QA test hook, added for
            // dev-task-1.5.0-hardening TF-2 — not in the original seed-arg table.
            (history as? FastHistoryRepository)?.seedFutureSchemaFile()
        } else if args.contains("-seedHistoryEdge") {
            history.replaceAll(edgeCaseRecords())
        } else if let count = intArg("-seedHistory") {
            history.replaceAll(dailyRecords(count: count))
        }
    }

    /// `count` fasts, one a day back from yesterday, with a single skipped day so
    /// the seven-day dots show a real gap.
    private static func dailyRecords(count: Int) -> [FastRecord] {
        let calendar = Calendar.current
        let plan = Plan(hours: 16)
        return (0..<max(0, count)).compactMap { index in
            // Skip four days back to leave one unfilled dot in the last week.
            let daysAgo = index >= 4 ? index + 2 : index + 1
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()),
                  let start = calendar.date(bySettingHour: 20, minute: (index * 13) % 60, second: 0, of: day)
            else { return nil }
            // 16h02m … 18h12m, varying so the rows don't look generated.
            let duration = 16 * 3600 + Double((index * 37) % 130) * 60
            return FastRecord(
                id: UUID(),
                startTimestamp: start.timeIntervalSince1970,
                endTimestamp: start.timeIntervalSince1970 + duration,
                goalHours: plan.fastHours,
                planLabel: plan.ratioLabel
            )
        }
    }

    /// The four data shapes the design has to survive: a fast across midnight, one
    /// past 40 hours, one that fell short of its goal, and two on the same day.
    private static func edgeCaseRecords() -> [FastRecord] {
        let calendar = Calendar.current
        let now = Date()

        func record(daysAgo: Int, hour: Int, minute: Int, duration: TimeInterval, plan: Plan) -> FastRecord? {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now),
                  let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
            else { return nil }
            return FastRecord(
                id: UUID(),
                startTimestamp: start.timeIntervalSince1970,
                endTimestamp: start.timeIntervalSince1970 + duration,
                goalHours: plan.fastHours,
                planLabel: plan.ratioLabel
            )
        }

        return [
            record(daysAgo: 2, hour: 21, minute: 20, duration: 16 * 3600 + 24 * 60, plan: Plan(hours: 16)),
            record(daysAgo: 4, hour: 18, minute: 0, duration: 41 * 3600 + 12 * 60, plan: Plan(hours: 20)),
            record(daysAgo: 6, hour: 22, minute: 0, duration: 9 * 3600 + 5 * 60, plan: Plan(hours: 16)),
            record(daysAgo: 6, hour: 11, minute: 0, duration: 6 * 3600 + 40 * 60, plan: Plan(hours: 16)),
        ].compactMap { $0 }
    }
}
#endif
