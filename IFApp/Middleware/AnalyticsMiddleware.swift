//
//  AnalyticsMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class AnalyticsMiddleware: Middleware {
    private let tracker: AnalyticsTrackerProtocol
    private var reportedPlan: Plan?
    private var reportedEntitlement: Entitlement?
    private var previousPro: ProState?
    private var previousSunnah: SunnahState?
    private var armingAwaitingAnswer = false

    init(tracker: AnalyticsTrackerProtocol = container.inject()) {
        self.tracker = tracker
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        let app = state as? AppState
        defer {
            if let app {
                previousPro = app.proState
                previousSunnah = app.sunnahState
            }
        }
        switch action {
        case let lifecycle as AppLifecycleAction:
            if case .appOpened = lifecycle, let app { reportCurrentPlan(app.planState.plan) }
            handle(lifecycle)
        case let timer as TimerAction:
            handle(timer, goalHours: app?.activeGoalHours ?? Plan.default.fastHours)
        case is PlanAction:
            if let app { handlePlanSelected(app.planState.plan) }
        case let ui as UIAction:
            if case .planEditorClosed = ui, let app {
                let plan = app.planState.plan
                tracker.log(.planConfirmed(plan: plan.analyticsLabel, goalHours: plan.hours))
            }
        case let history as HistoryAction:
            handle(history)
        case let pro as ProAction:
            handle(pro, trigger: trigger(after: app))
            if let app { reportProStatus(app.proState.entitlement) }
        case let endFast as EndFastAction:
            handle(endFast)
        case let sunnah as SunnahAction:
            if let app { handle(sunnah, settings: app.sunnahState.settings) }
        default:
            break
        }
    }

    private func handle(_ action: SunnahAction, settings: SunnahSettings) {
        switch action {
        case .settingsChanged:
            if !settings.enabled {
                armingAwaitingAnswer = false
            } else if previousSunnah?.settings.enabled == false {
                armingAwaitingAnswer = true
            }
        case let .deliveryUpdated(delivery, _):
            guard armingAwaitingAnswer else { return }
            armingAwaitingAnswer = false
            tracker.log(.sunnahEnabled(mode: settings.analyticsMode,
                                       pushAllowed: delivery != .denied))
        case .refresh, .systemSettingsTapped:
            break
        }
    }

    private func handle(_ action: EndFastAction) {
        if case let .refused(_, unavoidable) = action {
            tracker.log(.endFastRefused(unavoidable: unavoidable))
        }
    }

    private func handle(_ action: HistoryAction) {
        switch action {
        case .deleted:
            tracker.log(.historyRecordDeleted)
        case let .exportFinished(shared):
            if shared { tracker.log(.historyExported) }
        case .recorded, .exportTapped, .exportStarted, .exportFailed, .exportPrepared:
            break
        }
    }

    private func handle(_ action: ProAction, trigger: String) {
        switch action {
        case .offerOpened:
            tracker.log(.paywallShown(trigger: trigger))
        case .offerClosed:
            tracker.log(.paywallDismissed(trigger: trigger))
        case .purchaseStarted:
            tracker.log(.purchaseStarted(trigger: trigger, product: ProCatalog.productID))
        case .purchaseCompleted:
            tracker.log(.purchaseCompleted(trigger: trigger, product: ProCatalog.productID))
        case .purchasePending:
            tracker.log(.purchaseFailed(trigger: trigger, reason: PurchaseFailure.pending.rawValue))
        case let .purchaseFailed(reason), let .restoreFailed(reason):
            tracker.log(.purchaseFailed(trigger: trigger, reason: reason.rawValue))
        case .restoreCompleted:
            tracker.log(.restoreCompleted)
        case .restoreStarted, .restoreFoundNothing, .storeResolved, .entitlementChanged,
             .nothingToRestoreExpired, .noticeShown, .noticeDismissed,
             .autoOfferArmed, .autoOfferCancelled, .purchaseTapped, .restoreTapped:
            break
        }
    }

    private func trigger(after app: AppState?) -> String {
        (app?.proState.trigger ?? previousPro?.trigger ?? .unknown).rawValue
    }

    private func reportProStatus(_ entitlement: Entitlement) {
        guard entitlement != reportedEntitlement else { return }
        reportedEntitlement = entitlement
        tracker.setUserProperty(entitlement.analyticsValue, forName: "pro_status")
    }

    private func handle(_ action: AppLifecycleAction) {
        switch action {
        case .appOpened: tracker.log(.appOpened)
        case .sourcesOpened: tracker.log(.sourcesOpened)
        case let .sourceArticleOpened(articleID):
            tracker.log(.sourceArticleOpened(articleID: articleID))
        case let .sourceOriginalOpened(articleID, _):
            tracker.log(.sourceOriginalOpened(articleID: articleID))
        case let .sourceArticleClosed(articleID, reachedEnd):
            tracker.log(.sourceArticleClosed(articleID: articleID, reachedEnd: reachedEnd))
        case let .sunnahOpened(source): tracker.log(.sunnahOpened(source: source.rawValue))
        case let .historyOpened(source): tracker.log(.historyOpened(source: source.rawValue))
        case let .reviewPrompted(trigger): tracker.log(.reviewPrompted(trigger: trigger.rawValue))
        case let .streakMilestone(days): tracker.log(.streakMilestone(days: days))
        case .appBecameActive: break
        case .goalScreenSettled: break
        case .eatingWindowSettled: break
        case .pushAuthorizationResolved: break
        case let .pushStatusRead(label):
            tracker.setUserProperty(label, forName: "push_status")
        case let .lastMealLogged(backdated, minutesAgo, inputMethod):
            tracker.log(.lastMealLogged(backdated: backdated, minutesAgo: minutesAgo,
                                        inputMethod: inputMethod))
        case .fastChained:
            tracker.log(.fastChained)
        case let .themeActive(dark):
            tracker.log(.themeActive(dark: dark))
        }
    }

    private func handle(_ action: TimerAction, goalHours: Double) {
        switch action {
        case .started:
            tracker.log(.fastStarted(goalHours: goalHours))
        case let .stopped(elapsed, qualifies, backdatedMinutes):
            let phase = PhaseProgress.compute(elapsed: elapsed, goalHours: goalHours).phase
            tracker.log(.fastStopped(
                durationSeconds: Int(elapsed),
                completed: qualifies,
                stage: phase.analyticsValue,
                backdatedMinutes: backdatedMinutes
            ))
        case .stopUndone:
            tracker.log(.fastStopUndone)
        case let .reset(elapsed):
            tracker.log(.fastReset(elapsedMinutes: Int(elapsed / 60)))
        case .eatingStarted:
            tracker.log(.eatingWindowStarted)
        case .eatingEnded, .startFastTapped, .resumeTapped, .resetTapped, .startEatingTapped,
             .continueFastingTapped, .goalMomentStarted:
            break
        case .timeAdjusted:
            tracker.log(.timeAdjusted)
        case .goalCelebrated:
            tracker.log(.goalReached(goalHours: goalHours))
        }
    }

    private func handlePlanSelected(_ plan: Plan) {
        guard plan != reportedPlan else { return }
        tracker.log(.planSelected(plan: plan.analyticsLabel, goalHours: plan.hours))
        reportCurrentPlan(plan)
    }

    private func reportCurrentPlan(_ plan: Plan) {
        reportedPlan = plan
        tracker.setUserProperty(plan.analyticsLabel, forName: "current_plan")
    }
}
