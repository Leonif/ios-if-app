//
//  AnalyticsMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class AnalyticsMiddleware: Middleware {
    private let repo: AnalyticsRepositoryProtocol
    private var reportedPlan: Plan?
    private var reportedEntitlement: Entitlement?
    private var previousPro: ProState?
    private var previousSunnah: SunnahState?
    private var armingAwaitingAnswer = false

    init(repo: AnalyticsRepositoryProtocol = container.inject()) {
        self.repo = repo
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
                repo.log(.planConfirmed(plan: plan.analyticsLabel, goalHours: plan.hours))
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
            repo.log(.sunnahEnabled(mode: settings.analyticsMode,
                                    pushAllowed: delivery != .denied))
        case .refresh:
            break
        }
    }

    private func handle(_ action: EndFastAction) {
        if case let .refused(_, unavoidable) = action {
            repo.log(.endFastRefused(unavoidable: unavoidable))
        }
    }

    private func handle(_ action: HistoryAction) {
        switch action {
        case .deleted:
            repo.log(.historyRecordDeleted)
        case let .exportFinished(shared):
            if shared { repo.log(.historyExported) }
        case .recorded, .exportStarted, .exportFailed, .exportPrepared:
            break
        }
    }

    private func handle(_ action: ProAction, trigger: String) {
        switch action {
        case .offerOpened:
            repo.log(.paywallShown(trigger: trigger))
        case .offerClosed:
            repo.log(.paywallDismissed(trigger: trigger))
        case .purchaseStarted:
            repo.log(.purchaseStarted(trigger: trigger, product: ProCatalog.productID))
        case .purchaseCompleted:
            repo.log(.purchaseCompleted(trigger: trigger, product: ProCatalog.productID))
        case .purchasePending:
            repo.log(.purchaseFailed(trigger: trigger, reason: PurchaseFailure.pending.rawValue))
        case let .purchaseFailed(reason), let .restoreFailed(reason):
            repo.log(.purchaseFailed(trigger: trigger, reason: reason.rawValue))
        case .restoreCompleted:
            repo.log(.restoreCompleted)
        case .restoreStarted, .restoreFoundNothing, .storeResolved, .entitlementChanged,
             .nothingToRestoreExpired, .noticeShown, .noticeDismissed,
             .autoOfferArmed, .autoOfferCancelled:
            break
        }
    }

    private func trigger(after app: AppState?) -> String {
        (app?.proState.trigger ?? previousPro?.trigger ?? .unknown).rawValue
    }

    private func reportProStatus(_ entitlement: Entitlement) {
        guard entitlement != reportedEntitlement else { return }
        reportedEntitlement = entitlement
        repo.setUserProperty(entitlement.analyticsValue, forName: "pro_status")
    }

    private func handle(_ action: AppLifecycleAction) {
        switch action {
        case .appOpened: repo.log(.appOpened)
        case .sourcesOpened: repo.log(.sourcesOpened)
        case let .sourceArticleOpened(articleID):
            repo.log(.sourceArticleOpened(articleID: articleID))
        case let .sourceOriginalOpened(articleID):
            repo.log(.sourceOriginalOpened(articleID: articleID))
        case let .sourceArticleClosed(articleID, reachedEnd):
            repo.log(.sourceArticleClosed(articleID: articleID, reachedEnd: reachedEnd))
        case let .sunnahOpened(source): repo.log(.sunnahOpened(source: source.rawValue))
        case let .historyOpened(source): repo.log(.historyOpened(source: source.rawValue))
        case let .reviewPrompted(trigger): repo.log(.reviewPrompted(trigger: trigger.rawValue))
        case let .streakMilestone(days): repo.log(.streakMilestone(days: days))
        case .appBecameActive: break
        case .goalScreenSettled: break
        case .pushAuthorizationResolved: break
        case let .lastMealLogged(backdated, minutesAgo, inputMethod):
            repo.log(.lastMealLogged(backdated: backdated, minutesAgo: minutesAgo,
                                     inputMethod: inputMethod))
        case .fastChained:
            repo.log(.fastChained)
        case let .themeActive(dark):
            repo.log(.themeActive(dark: dark))
        }
    }

    private func handle(_ action: TimerAction, goalHours: Double) {
        switch action {
        case .started:
            repo.log(.fastStarted(goalHours: goalHours))
        case let .stopped(elapsed, qualifies, backdatedMinutes):
            let phase = PhaseProgress.compute(elapsed: elapsed, goalHours: goalHours).phase
            repo.log(.fastStopped(
                durationSeconds: Int(elapsed),
                completed: qualifies,
                stage: phase.analyticsValue,
                backdatedMinutes: backdatedMinutes
            ))
        case .stopUndone:
            repo.log(.fastStopUndone)
        case let .reset(elapsed):
            repo.log(.fastReset(elapsedMinutes: Int(elapsed / 60)))
        case .eatingStarted:
            repo.log(.eatingWindowStarted)
        case .eatingEnded:
            break
        case .timeAdjusted:
            repo.log(.timeAdjusted)
        case .goalCelebrated:
            repo.log(.goalReached(goalHours: goalHours))
        }
    }

    private func handlePlanSelected(_ plan: Plan) {
        guard plan != reportedPlan else { return }
        repo.log(.planSelected(plan: plan.analyticsLabel, goalHours: plan.hours))
        reportCurrentPlan(plan)
    }

    private func reportCurrentPlan(_ plan: Plan) {
        reportedPlan = plan
        repo.setUserProperty(plan.analyticsLabel, forName: "current_plan")
    }
}
