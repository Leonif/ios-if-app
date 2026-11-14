//
//  AppStoreFactory.swift
//  IFApp
//

import Foundation
import Redux

enum AppStoreFactory {
    static func make() -> Store<AppState> {
        let notifications: NotificationRepositoryProtocol = container.inject()
        notifications.enableForegroundPresentation()

        let persistence: TimerPersistenceRepositoryProtocol = container.inject()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uitestReset") {
            let sunnah: SunnahRepositoryProtocol = container.inject()
            sunnah.save(SunnahSettings())
            persistence.save(fastStartTimestamp: 0, goalHours: 0, isRunning: false, completedSessions: 0, hasCelebrated: false, eatingStartTimestamp: 0, isEating: false, stagedElapsed: 0, fastEndTimestamp: 0, streakCount: 0, lastGoalDate: nil, freezeSpentMonth: nil)
            let history: FastHistoryRepositoryProtocol = container.inject()
            (history as? FastHistoryRepository)?.wipeFile()
        }
        UITestSeed.applyIfNeeded()
        FontMetricsDump.runIfNeeded()
        #endif
        let loaded = persistence.load()
        let history: FastHistoryRepositoryProtocol = container.inject()
        let offer: ProOfferRepositoryProtocol = container.inject()

        let sunnah: SunnahRepositoryProtocol = container.inject()
        var initialState = AppState(
            timerState: TimerState(
                fastStartTimestamp: loaded.fastStartTimestamp,
                goalHours: loaded.goalHours,
                isRunning: loaded.isRunning,
                stagedElapsed: loaded.stagedElapsed,
                fastEndTimestamp: loaded.fastEndTimestamp,
                completedSessionsCount: loaded.completedSessions,
                hasCelebrated: loaded.hasCelebrated,
                eatingStartTimestamp: loaded.eatingStartTimestamp,
                isEating: loaded.isEating,
                streakCount: loaded.streakCount,
                lastGoalDate: loaded.lastGoalDate,
                freezeSpentMonth: loaded.freezeSpentMonth
            ),
            planState: PlanState(plan: persistence.loadPlanHours().map(Plan.init(hours:)) ?? .default),
            historyState: HistoryState(records: history.loadAll().sorted { $0.startTimestamp > $1.startTimestamp }),
            proState: ProState(autoOfferShown: offer.wasOfferShown()),
            sunnahState: SunnahState(settings: sunnah.load())
        )
        initialState.timerState = initialState.timerState
            .droppingLapsedEnding(at: Clock.now().timeIntervalSince1970, plan: initialState.activePlan)

        var middlewares: [Middleware] = [
            PersistenceMiddleware(),
            HistoryMiddleware(),
            StreakMiddleware(),
            ReviewMiddleware(),
            AnalyticsMiddleware(),
            NotificationMiddleware(),
            SunnahMiddleware(),
            StoreMiddleware(),
        ]
        #if DEBUG || DEVELOPMENT
        middlewares.insert(DiagnosticsMiddleware(), at: 0)
        #endif

        let core = ImprovedStoreV2(
            state: initialState,
            reducer: rootReducer,
            middlewares: middlewares
        )

        let store = Store(store: core)
        container.register(Store<AppState>.self) { store }
        return store
    }
}
