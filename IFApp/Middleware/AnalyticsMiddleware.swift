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

    init(repo: AnalyticsRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        let app = state as? AppState
        switch action {
        case let lifecycle as AppLifecycleAction:
            if case .appOpened = lifecycle, let app { reportCurrentPlan(app.planState.plan) }
            handle(lifecycle)
        case let timer as TimerAction:
            handle(timer, goalHours: app?.planState.plan.fastHours ?? Plan.default.fastHours)
        case is PlanAction:
            // State here is post-reduce, so `plan` is already the saved choice.
            if let app { handlePlanSelected(app.planState.plan) }
        case let ui as UIAction:
            if case .planEditorClosed = ui, let app {
                let plan = app.planState.plan
                repo.log(.planConfirmed(plan: plan.ratioLabel, goalHours: Int(plan.fastHours)))
            }
        case let history as HistoryAction:
            if case .deleted = history { repo.log(.historyRecordDeleted) }
        default:
            break
        }
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
                stage: phase.label
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
        repo.log(.planSelected(plan: plan.ratioLabel, goalHours: Int(plan.fastHours)))
        reportCurrentPlan(plan)
    }

    /// Keeps `current_plan` on the user. Set on cold start too, so reports can be
    /// segmented by plan for the majority who never open the editor.
    private func reportCurrentPlan(_ plan: Plan) {
        reportedPlan = plan
        repo.setUserProperty(plan.ratioLabel, forName: "current_plan")
    }
}
