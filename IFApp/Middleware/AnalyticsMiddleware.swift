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
        switch action {
        case let lifecycle as AppLifecycleAction:
            handle(lifecycle)
        case let timer as TimerAction:
            handle(timer)
        default:
            break
        }
    }

    private func handle(_ action: AppLifecycleAction) {
        switch action {
        case .appOpened: repo.log(.appOpened)
        case .sourcesOpened: repo.log(.sourcesOpened)
        case .reviewPrompted: repo.log(.reviewPrompted)
        }
    }

    private func handle(_ action: TimerAction) {
        switch action {
        case .started:
            repo.log(.fastStarted)
        case let .stopped(elapsed, qualifies):
            let stage = TimeStage.determineStage(from: elapsed)
            repo.log(.fastStopped(
                durationSeconds: Int(elapsed),
                completed: qualifies,
                stage: stage.displayString
            ))
        case .reset:
            repo.log(.fastReset)
        case .timeAdjusted:
            repo.log(.timeAdjusted)
        }
    }
}
