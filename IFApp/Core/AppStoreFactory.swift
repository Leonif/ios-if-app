//
//  AppStoreFactory.swift
//  IFApp
//
//  Builds the app store: loads persisted state into the initial AppState,
//  wires middlewares, and registers the store in the container.
//

import Foundation
import Redux

enum AppStoreFactory {
    static func make() -> Store<AppState> {
        let persistence: TimerPersistenceRepositoryProtocol = container.inject()
        // UI tests launch with "-uitestReset" to start from a clean idle state.
        if ProcessInfo.processInfo.arguments.contains("-uitestReset") {
            persistence.save(fastStartTimestamp: 0, isRunning: false, completedSessions: 0, hasCelebrated: false, eatingStartTimestamp: 0, isEating: false, streakCount: 0, lastGoalDate: nil)
        }
        // UI tests also seed timer/review state via "-seed…" args (see UITestSeed).
        #if DEBUG
        UITestSeed.applyIfNeeded()
        #endif
        let loaded = persistence.load()

        let initialState = AppState(
            timerState: TimerState(
                fastStartTimestamp: loaded.fastStartTimestamp,
                isRunning: loaded.isRunning,
                stagedElapsed: 0,
                completedSessionsCount: loaded.completedSessions,
                hasCelebrated: loaded.hasCelebrated,
                eatingStartTimestamp: loaded.eatingStartTimestamp,
                isEating: loaded.isEating,
                streakCount: loaded.streakCount,
                lastGoalDate: loaded.lastGoalDate
            ),
            planState: PlanState(planIdx: persistence.loadPlanIdx() ?? Plan.default.rawValue)
        )

        let core = ImprovedStoreV2(
            state: initialState,
            reducer: rootReducer,
            middlewares: [
                PersistenceMiddleware(),
                StreakMiddleware(),
                ReviewMiddleware(),
                AnalyticsMiddleware(),
                NotificationMiddleware(),
            ]
        )

        let store = Store(store: core)
        container.register(Store<AppState>.self) { store }
        return store
    }
}
