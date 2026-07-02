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
            persistence.save(fastStartTimestamp: 0, isRunning: false, completedSessions: 0)
        }
        let loaded = persistence.load()

        let initialState = AppState(
            timerState: TimerState(
                fastStartTimestamp: loaded.fastStartTimestamp,
                isRunning: loaded.isRunning,
                stagedElapsed: 0,
                completedSessionsCount: loaded.completedSessions
            ),
            planState: PlanState(planIdx: persistence.loadPlanIdx() ?? Plan.default.rawValue)
        )

        let core = ImprovedStoreV2(
            state: initialState,
            reducer: rootReducer,
            middlewares: [
                PersistenceMiddleware(),
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
