//
//  AppStoreFactory.swift
//  IFApp
//
//  Builds the app store: loads persisted state into the initial AppState,
//  wires middlewares, and registers the store in the container.
//

import Redux

enum AppStoreFactory {
    static func make() -> Store<AppState> {
        let persistence: TimerPersistenceRepositoryProtocol = container.inject()
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
