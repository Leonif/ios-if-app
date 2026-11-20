//
//  HistoryMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class HistoryMiddleware: Middleware {
    private static let minimumDuration: TimeInterval = 60

    private var previousTimer: TimerState?
    private var previousPlan: Plan = .default

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
        case let HistoryAction.deleted(id):
            dispatch(DeleteFastRecordThunk(id: id))
        case HistoryAction.exportTapped:
            dispatch(ExportHistoryThunk())
        default:
            break
        }
    }

    private func record(_ action: TimerAction, dispatch: DispatchFunction) {
        guard let before = previousTimer, before.isRunning, before.fastStartTimestamp > 0 else { return }

        let end: Double
        switch action {
        case let .stopped(elapsed, _, _):
            end = before.fastStartTimestamp + elapsed
        default:
            return
        }

        guard end - before.fastStartTimestamp >= Self.minimumDuration else { return }

        let goalHours = before.resolvedGoalHours(planHours: previousPlan.fastHours)
        let record = FastRecord(
            id: UUID(),
            startTimestamp: before.fastStartTimestamp,
            endTimestamp: end,
            goalHours: goalHours,
            planLabel: Plan(goalHours: goalHours).ratioLabel
        )
        dispatch(SaveFastRecordThunk(record: record))
    }
}
