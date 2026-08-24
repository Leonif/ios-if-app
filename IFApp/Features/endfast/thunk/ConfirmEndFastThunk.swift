//
//  ConfirmEndFastThunk.swift
//  IFApp
//
//  The single point a fast ends. It replaces `StopFastThunk`, which ended the fast
//  at the moment of the tap because there was nowhere else for the moment to come
//  from; here it comes from the sheet, and the tap is only what confirms it.
//
//  The overlap guard lives here rather than in `HistoryMiddleware` for the reason
//  the refusal state exists at all: a write that quietly does not happen is the
//  silent "no". Middleware has no way to say anything, so the check runs where an
//  answer can still be given.
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
        // Re-clamped against the clock as it stands at the tap, not as it stood when
        // the control last moved: a sheet left open crosses no boundary while it sits
        // there, but "now" has moved on, and only this side of it may be written.
        let end = min(max(sheet.endTimestamp, start + EndFastState.minimumFastDuration), now)

        if let conflict = FastRecord.firstOverlap(in: app.historyState.records, start: start, end: end) {
            // If even the shortest allowed fast — ending the instant it is old enough —
            // still overlaps, the clash is on the start, and no end the person could
            // pick would clear it. Say so, so the refusal can drop "pick another time"
            // instead of looping them back to the same wall.
            let earliestEnd = min(start + EndFastState.minimumFastDuration, now)
            let unavoidable = FastRecord.firstOverlap(in: app.historyState.records,
                                                      start: start, end: earliestEnd) != nil
            dispatch(EndFastAction.refused(conflict: conflict, unavoidable: unavoidable))
            return
        }

        let elapsed = max(0, end - start)
        // Analytics-only flag (`fast_stopped.completed`) — it gates nothing. It is now
        // computed from the confirmed end rather than from the tap, which is the whole
        // point of the feature: a fast abandoned before its goal stops reading as taken.
        let qualifies = elapsed >= app.activeGoalHours * 3600
        let backdatedMinutes = Int(((now - end) / 60).rounded())

        dispatch(TimerAction.stopped(elapsed: elapsed,
                                     qualifiesAsCompleted: qualifies,
                                     backdatedMinutes: backdatedMinutes))
        dispatch(EndFastAction.closed)

        // T1'. The fast that just ended is the only thing that can arm the one-time
        // offer, and this is the last point where its elapsed time still exists —
        // `.stopped` stages it, but the goal it ran to is resolved here.
        //
        // Arming is not showing. The moment comes later, once the user has left the
        // complete state through the eating window; everything in between (a rollback,
        // a Reset, a review prompt, the session simply ending) cancels or suppresses
        // it without costing the show.
        if OfferQualification.qualifies(elapsed: elapsed, goalHours: app.activeGoalHours) {
            dispatch(ProAction.autoOfferArmed)
        }
    }
}
