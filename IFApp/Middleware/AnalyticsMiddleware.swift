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

    init(repo: AnalyticsRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        let app = state as? AppState
        switch action {
        case let lifecycle as AppLifecycleAction:
            handle(lifecycle)
        case let timer as TimerAction:
            handle(timer, goalHours: app?.planState.plan.fastHours ?? Plan.default.fastHours)
        default:
            break
        }
    }

    private func handle(_ action: AppLifecycleAction) {
        switch action {
        case .appOpened: repo.log(.appOpened)
        case .sourcesOpened: repo.log(.sourcesOpened)
        case let .reviewPrompted(trigger): repo.log(.reviewPrompted(trigger: trigger.rawValue))
        case let .streakMilestone(days): repo.log(.streakMilestone(days: days))
        case .appBecameActive: break     // internal gate signal, not a funnel event
        case .goalScreenSettled: break   // internal gate signal, not a funnel event
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
        case .reset:
            repo.log(.fastReset)
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
}
