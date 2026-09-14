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
        // First, before anything is loaded or scheduled: a push already due at launch
        // (a window that closed while the app was opening) must find the delegate in
        // place, or iOS drops it on the floor while the app is in the foreground.
        let notifications: NotificationRepositoryProtocol = container.inject()
        notifications.enableForegroundPresentation()

        let persistence: TimerPersistenceRepositoryProtocol = container.inject()
        // Test hooks, DEBUG-only as a block. "-uitestReset" wipes the timer defaults
        // *and* the whole history file; a hook that destructive has no business in a
        // store binary, even though a user has no way to pass a launch argument.
        // The suite runs on DEBUG builds, so nothing it needs is lost.
        #if DEBUG
        // UI tests launch with "-uitestReset" to start from a clean idle state.
        if ProcessInfo.processInfo.arguments.contains("-uitestReset") {
            let sunnah: SunnahRepositoryProtocol = container.inject()
            sunnah.save(SunnahSettings())
            persistence.save(fastStartTimestamp: 0, goalHours: 0, isRunning: false, completedSessions: 0, hasCelebrated: false, eatingStartTimestamp: 0, isEating: false, stagedElapsed: 0, fastEndTimestamp: 0, streakCount: 0, lastGoalDate: nil, freezeSpentMonth: nil)
            let history: FastHistoryRepositoryProtocol = container.inject()
            // Not `replaceAll([])`: it is bound by the TF-2 write guard, and this is
            // the branch that has to survive a future-schema file left by an earlier
            // flow. It is also the only wipe a "-uitestReset" launch gets — with no
            // "-seed…" argument `UITestSeed.applyIfNeeded` returns before its own.
            (history as? FastHistoryRepository)?.wipeFile()
        }
        // UI tests also seed timer/review state via "-seed…" args (see UITestSeed).
        UITestSeed.applyIfNeeded()
        // "-dumpFontMetrics" measures the UIFontMetrics curve. It writes a file, so it
        // is a side effect like any other; it lives in `Debug/` for that reason (the
        // invariant-2 exception, 07.08.2026) and is merely *called* from here.
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
                // Restored so the result screen survives iOS unloading the app on
                // it: without these a finished fast relaunched into idle, the eating
                // window was never opened, and its closing push never came.
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
            // The only part of the offer that survives a launch. Everything else the
            // automatic trigger needs is session state and starts empty by design.
            proState: ProState(autoOfferShown: offer.wasOfferShown()),
            sunnahState: SunnahState(settings: sunnah.load())
        )
        // A result screen restored from disk is held only while the window it would open
        // is still current (`TimerState.droppingLapsedEnding`). Decided here, once, on
        // the clock at launch: clearing it in the state rather than hiding it on screen
        // keeps every thunk that reads the staged ending — the start that back-dates by
        // it, the undo, the window anchor — from acting on a week-old fast.
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
        // First in the list on purpose: an action that wedges a later middleware is
        // already on disk by the time it does.
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
