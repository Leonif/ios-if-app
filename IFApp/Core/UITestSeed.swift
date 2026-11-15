//
//  UITestSeed.swift
//  IFApp
//

#if DEBUG
import Foundation

enum UITestSeed {
    static func applyIfNeeded(_ defaults: UserDefaults = .standard) {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains(where: { $0.hasPrefix("-seed") }) else { return }

        defaults.set(0.0, forKey: "start_timestamp")
        defaults.set(0.0, forKey: "goal_hours")
        defaults.set(false, forKey: "is_running")
        defaults.set(0, forKey: "completed_sessions_count")
        defaults.set(false, forKey: "has_celebrated")
        defaults.set(0.0, forKey: "eating_start_timestamp")
        defaults.set(false, forKey: "is_eating")
        defaults.set(0.0, forKey: "staged_elapsed")
        defaults.set(0.0, forKey: "fast_end_timestamp")
        defaults.set(0, forKey: "streak_count")
        defaults.removeObject(forKey: "streak_last_goal_date")
        defaults.removeObject(forKey: "streak_freeze_spent_month")
        defaults.set(0, forKey: "streak_last_milestone_shown")
        defaults.removeObject(forKey: "plan_hours")
        defaults.removeObject(forKey: "plan_idx")
        defaults.removeObject(forKey: "review_last_shown")
        defaults.set(0, forKey: "review_prompt_count")
        defaults.set(false, forKey: "pro_offer_shown")

        func intArg(_ name: String) -> Int? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return Int(args[i + 1])
        }

        if let sec = intArg("-seedElapsed") {
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "start_timestamp")
            defaults.set(true, forKey: "is_running")
            defaults.set(defaults.double(forKey: "goal_hours") > 0
                         ? defaults.double(forKey: "goal_hours")
                         : Double(Plan.default.hours), forKey: "goal_hours")
        }
        if let sec = intArg("-seedEatingElapsed") {
            defaults.set(Date().timeIntervalSince1970 - Double(sec), forKey: "eating_start_timestamp")
            defaults.set(true, forKey: "is_eating")
            defaults.set(false, forKey: "is_running")
            defaults.set(Double(Plan.default.hours), forKey: "goal_hours")
        }
        if let c = intArg("-seedCount") { defaults.set(c, forKey: "completed_sessions_count") }
        if let cel = intArg("-seedCelebrated") { defaults.set(cel == 1, forKey: "has_celebrated") }
        if let p = intArg("-seedPlanHours"), Plan.range.contains(p) {
            defaults.set(p, forKey: "plan_hours")
            if defaults.bool(forKey: "is_running") || defaults.bool(forKey: "is_eating") {
                defaults.set(Double(p), forKey: "goal_hours")
            }
        }
        if let g = intArg("-seedGoalHours") { defaults.set(Double(g), forKey: "goal_hours") }
        if let pc = intArg("-seedPromptCount") { defaults.set(pc, forKey: "review_prompt_count") }
        if let shown = intArg("-seedOfferShown") { defaults.set(shown == 1, forKey: "pro_offer_shown") }
        if let s = intArg("-seedStreak") { defaults.set(s, forKey: "streak_count") }
        if intArg("-seedStreak") != nil || intArg("-seedLastGoalDate") != nil {
            let daysAgo = intArg("-seedLastGoalDate") ?? 0
            let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            defaults.set(Clock.dayKey(day), forKey: "streak_last_goal_date")
        }
        if intArg("-seedFreezeSpent") == 1 {
            let today = Clock.dayKey()
            let gapMonth = defaults.string(forKey: "streak_last_goal_date").flatMap { goal -> String? in
                guard (Clock.daysBetween(goal, today) ?? 0) >= 2 else { return nil }
                return StreakStatus.freezeMonthCharged(afterGoalOn: goal)
            }
            defaults.set(gapMonth ?? Clock.monthKey(ofDay: today), forKey: "streak_freeze_spent_month")
        }

        let daysBack = intArg("-seedHistoryDaysBack") ?? 0

        let history: FastHistoryRepositoryProtocol = container.inject()
        (history as? FastHistoryRepository)?.wipeFile()
        if args.contains("-seedHistoryCorrupt") {
            (history as? FastHistoryRepository)?.seedCorruptFile()
        } else if args.contains("-seedHistoryFutureSchema") {
            (history as? FastHistoryRepository)?.seedFutureSchemaFile()
        } else if args.contains("-seedHistoryEdge") {
            let records = edgeCaseRecords(daysBack: daysBack)
            history.replaceAll(records)
            warnIfSeededHistoryCollides(records, elapsed: intArg("-seedElapsed"))
        } else if let count = intArg("-seedHistory") {
            let records = dailyRecords(count: count, daysBack: daysBack)
            history.replaceAll(records)
            warnIfSeededHistoryCollides(records, elapsed: intArg("-seedElapsed"))
        }
    }

    private static func warnIfSeededHistoryCollides(_ records: [FastRecord], elapsed: Int?) {
        guard let elapsed else { return }
        let now = Date().timeIntervalSince1970
        guard let conflict = FastRecord.firstOverlap(in: records,
                                                     start: now - Double(elapsed),
                                                     end: now) else { return }
        let log: DiagnosticsLogRepositoryProtocol = container.inject()
        let stamp = ISO8601DateFormatter()
        log.append("""
            SEED WARNING: the seeded fast (-seedElapsed \(elapsed), \
            \(stamp.string(from: Date(timeIntervalSince1970: now - Double(elapsed)))) → \
            \(stamp.string(from: Date(timeIntervalSince1970: now)))) overlaps a seeded \
            history record (\(stamp.string(from: Date(timeIntervalSince1970: conflict.startTimestamp))) → \
            \(stamp.string(from: Date(timeIntervalSince1970: conflict.endTimestamp)))). \
            Ending this fast will hit the IF-5 overlap refusal. If that is not what the \
            flow is testing, push the seeded history back with "-seedHistoryDaysBack N".
            """)
    }

    private static func dailyRecords(count: Int, daysBack: Int = 0) -> [FastRecord] {
        let calendar = Calendar.current
        let plan = Plan(hours: 16)
        return (0..<max(0, count)).compactMap { index in
            let daysAgo = (index >= 4 ? index + 2 : index + 1) + max(0, daysBack)
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()),
                  let start = calendar.date(bySettingHour: 20, minute: (index * 13) % 60, second: 0, of: day)
            else { return nil }
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

    private static func edgeCaseRecords(daysBack: Int = 0) -> [FastRecord] {
        let calendar = Calendar.current
        let now = Date()

        func record(daysAgo: Int, hour: Int, minute: Int, duration: TimeInterval, plan: Plan) -> FastRecord? {
            guard let day = calendar.date(byAdding: .day, value: -(daysAgo + max(0, daysBack)), to: now),
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
