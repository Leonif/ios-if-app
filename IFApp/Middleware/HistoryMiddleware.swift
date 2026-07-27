//
//  HistoryMiddleware.swift
//  IFApp
//
//  The single place a finished fast is written. Living here rather than in the
//  thunks keeps one rule for every ending: End fast from active or overtime writes
//  a record; Reset discards the fast and writes nothing, which is what the reset
//  confirm sheet promises the user.
//
//  Middleware sees state *after* the reducer, so the fast being ended is already
//  gone from it; the snapshot below carries the timer state as it was one action
//  ago, which is what the record is built from.
//

import Foundation
import Redux

final class HistoryMiddleware: Middleware {
    /// Shorter than a minute is a mis-tap, not a fast.
    private static let minimumDuration: TimeInterval = 60

    private let repo: FastHistoryRepositoryProtocol
    /// Timer state as of the previous action — i.e. before the one being handled.
    private var previousTimer: TimerState?
    private var previousPlan: Plan = .default

    init(repo: FastHistoryRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let app = state as? AppState else { return }
        defer {
            previousTimer = app.timerState
            previousPlan = app.planState.plan
        }

        switch action {
        case let timer as TimerAction:
            record(timer, dispatch: dispatch)
        case let history as HistoryAction:
            if case let .deleted(id) = history { repo.delete(id: id) }
        default:
            break
        }
    }

    private func record(_ action: TimerAction, dispatch: DispatchFunction) {
        guard let before = previousTimer, before.isRunning, before.fastStartTimestamp > 0 else { return }

        let end: Double
        switch action {
        case let .stopped(elapsed, _):
            // Trust the thunk's elapsed — it already resolved the clock once.
            end = before.fastStartTimestamp + elapsed
        default:
            // .reset discards the fast — the confirm sheet promises exactly that,
            // so nothing is written. .started / .eatingStarted / .goalCelebrated /
            // .timeAdjusted / .eatingEnded never end a running fast.
            return
        }

        guard end - before.fastStartTimestamp >= Self.minimumDuration else { return }

        let record = FastRecord(
            id: UUID(),
            startTimestamp: before.fastStartTimestamp,
            endTimestamp: end,
            goalHours: previousPlan.fastHours,
            planLabel: previousPlan.ratioLabel
        )
        repo.append(record)
        dispatch(HistoryAction.recorded(record))
    }
}
