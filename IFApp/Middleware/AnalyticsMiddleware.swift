//
//  AnalyticsMiddleware.swift
//  IFApp
//
//  Central analytics: translates Redux actions into funnel events. This is the
//  single place that decides what gets tracked, so the user journey is auditable.
//

import Foundation
import Redux

final class AnalyticsMiddleware: Middleware {
    private let repo: AnalyticsRepositoryProtocol
    /// The plan last reported as the `current_plan` user property. Tapping the
    /// plan that is already selected is not a selection, so it must not re-fire.
    private var reportedPlan: Plan?
    /// The entitlement last written to `pro_status`, so the property is set once per
    /// actual change rather than on every action that carries the state along.
    private var reportedEntitlement: Entitlement?
    /// Pro substate as of the previous action — i.e. before the one being handled.
    /// Middleware sees state *after* the reducer, and the dismissal event needs the
    /// trigger the reducer has just cleared; this snapshot is where it still exists.
    /// Same device as `HistoryMiddleware.previousTimer`, for the same reason.
    private var previousPro: ProState?

    init(repo: AnalyticsRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        let app = state as? AppState
        defer { if let app { previousPro = app.proState } }
        switch action {
        case let lifecycle as AppLifecycleAction:
            if case .appOpened = lifecycle, let app { reportCurrentPlan(app.planState.plan) }
            handle(lifecycle)
        case let timer as TimerAction:
            handle(timer, goalHours: app?.activeGoalHours ?? Plan.default.fastHours)
        case is PlanAction:
            // State here is post-reduce, so `plan` is already the saved choice.
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
        default:
            break
        }
    }

    private func handle(_ action: HistoryAction) {
        switch action {
        case .deleted:
            repo.log(.historyRecordDeleted)
        case let .exportFinished(shared):
            // Only a share that went through. Opening the sheet and backing out is
            // not an export, and counting it would inflate the one number the
            // import decision will be read off.
            if shared { repo.log(.historyExported) }
        case .recorded, .exportPrepared:
            // Saving a fast is already covered by `fast_stopped`; writing the file is
            // a step on the way, not the act.
            break
        }
    }

    /// The offer and the purchase. Every event here carries `trigger`, because at
    /// 20-35 shows a month the distribution over entry points is the only thing this
    /// release can actually read; a conversion rate off 0-1 purchases cannot be.
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
            // Ask to Buy is not a purchase and not yet a loss — it is logged as the
            // reason the attempt did not end in Pro, and may still be approved later.
            repo.log(.purchaseFailed(trigger: trigger, reason: PurchaseFailure.pending.rawValue))
        case let .purchaseFailed(reason), let .restoreFailed(reason):
            repo.log(.purchaseFailed(trigger: trigger, reason: reason.rawValue))
        case .restoreCompleted:
            repo.log(.restoreCompleted)
        case .restoreStarted, .restoreFoundNothing, .storeResolved, .entitlementChanged,
             .nothingToRestoreExpired, .noticeShown, .noticeDismissed:
            // Reading the entitlement is not a funnel step; the property below carries
            // the outcome. Restore that finds nothing is the same non-event, and the
            // two notices report something the user did not do.
            break
        }
    }

    /// The entry point to report. The state holds it while the offer is up; on the
    /// dismissal the reducer has already cleared it, so the pre-reduce snapshot
    /// answers. Restore can also be run from the About sheet with no offer open at
    /// all — the trigger is then `manual`, which is the door that sheet is.
    private func trigger(after app: AppState?) -> String {
        (app?.proState.trigger ?? previousPro?.trigger ?? .manual).rawValue
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
        case let .historyOpened(source): repo.log(.historyOpened(source: source.rawValue))
        case let .reviewPrompted(trigger): repo.log(.reviewPrompted(trigger: trigger.rawValue))
        case let .streakMilestone(days): repo.log(.streakMilestone(days: days))
        case .appBecameActive: break     // internal gate signal, not a funnel event
        case .goalScreenSettled: break   // internal gate signal, not a funnel event
        case .pushAuthorizationResolved: break // re-schedule signal, not a funnel event
        case let .lastMealLogged(backdated, minutesAgo):
            repo.log(.lastMealLogged(backdated: backdated, minutesAgo: minutesAgo))
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
        case let .stopped(elapsed, qualifies):
            let phase = PhaseProgress.compute(elapsed: elapsed, goalHours: goalHours).phase
            repo.log(.fastStopped(
                durationSeconds: Int(elapsed),
                completed: qualifies,
                stage: phase.analyticsValue
            ))
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

    /// The plan editor saved a choice: one event plus the persistent property.
    private func handlePlanSelected(_ plan: Plan) {
        guard plan != reportedPlan else { return }
        repo.log(.planSelected(plan: plan.analyticsLabel, goalHours: plan.hours))
        reportCurrentPlan(plan)
    }

    /// Keeps `current_plan` on the user. Set on cold start too, so reports can be
    /// segmented by plan for the majority who never open the editor.
    private func reportCurrentPlan(_ plan: Plan) {
        reportedPlan = plan
        repo.setUserProperty(plan.analyticsLabel, forName: "current_plan")
    }
}
