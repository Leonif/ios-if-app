//
//  ConfirmEndFastThunk.swift
//  IFApp
//

import Foundation
import Redux

struct ConfirmEndFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let sheet = app.endFastState
        let timer = app.timerState
        guard sheet.isOpen, timer.isRunning, timer.fastStartTimestamp > 0 else { return }

        let now = Clock.now().timeIntervalSince1970
        let start = timer.fastStartTimestamp
        let end = min(max(sheet.endTimestamp, start + EndFastState.minimumFastDuration), now)

        if let conflict = FastRecord.firstOverlap(in: app.historyState.records, start: start, end: end) {
            let earliestEnd = min(start + EndFastState.minimumFastDuration, now)
            let unavoidable = FastRecord.firstOverlap(in: app.historyState.records,
                                                      start: start, end: earliestEnd) != nil
            dispatch(EndFastAction.refused(conflict: conflict, unavoidable: unavoidable))
            return
        }

        let elapsed = max(0, end - start)
        let qualifies = elapsed >= app.activeGoalHours * 3600
        let backdatedMinutes = Int(((now - end) / 60).rounded())

        dispatch(TimerAction.stopped(elapsed: elapsed,
                                     qualifiesAsCompleted: qualifies,
                                     backdatedMinutes: backdatedMinutes))
        dispatch(EndFastAction.closed)

        if OfferQualification.qualifies(elapsed: elapsed, goalHours: app.activeGoalHours) {
            dispatch(ProAction.autoOfferArmed)
        }
    }
}
