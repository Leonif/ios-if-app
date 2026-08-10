//
//  ResumeFastThunk.swift
//  IFApp
//
//  Undo of "End fast", offered on the result screen. End fast is one tap and stays
//  one tap; what this buys is the way back from a mis-tap, which the confirm sheet
//  would have taxed every intentional ending to prevent.
//
//  Deliberately not `StartFastThunk`: that one pins `goalHours` from the plan as it
//  stands now, so undoing a fast that ran to a different goal would silently rewrite
//  the goal it ran to. Undo restores the fast, it does not begin one.
//

import Foundation
import Redux

struct ResumeFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        // Only from the result screen: a fast in flight has nothing to undo, and a
        // zero staged elapsed means there is no ended fast on screen either.
        guard !timer.isRunning, timer.stagedElapsed > 0 else { return }

        // The record the ending just wrote goes with it — it describes a fast that,
        // as far as the user is concerned, never ended.
        if let record = justRecorded(app) {
            dispatch(HistoryAction.deleted(id: record.id))
        }

        // The clock is read here rather than in the reducer (invariant 1); where that
        // moment puts the start is `TimerState`'s rule, shared with the start path.
        let startTimestamp = timer.startTimestamp(at: Date().timeIntervalSince1970)
        dispatch(TimerAction.stopUndone(startTimestamp: startTimestamp))

        // The ending that armed the offer is being taken back, so the show armed for
        // it goes with it — the flag stays whole. This is the main thing standing
        // between a mis-tapped End fast and a lifetime offer spent on it: a stray
        // ending at 60% of the goal clears the quality threshold perfectly well.
        dispatch(ProAction.autoOfferCancelled)
    }

    /// The record written by the ending being undone, if there is one.
    ///
    /// Identified by duration rather than by a remembered id: `HistoryMiddleware`
    /// builds the record with `end - start == elapsed`, and that same `elapsed` is
    /// what `.stopped` staged, so the two are the same `Double` and not merely close.
    /// The check is what makes the delete safe in the case that has no record at all —
    /// a fast under `HistoryMiddleware.minimumDuration` is never written, and deleting
    /// "the newest record" would then throw away someone's previous fast.
    private func justRecorded(_ app: AppState) -> FastRecord? {
        guard let newest = app.historyState.records.first,
              abs(newest.duration - app.timerState.stagedElapsed) < 1
        else { return nil }
        return newest
    }
}
