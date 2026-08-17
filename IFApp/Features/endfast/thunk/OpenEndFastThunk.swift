//
//  OpenEndFastThunk.swift
//  IFApp
//
//  "End fast" no longer ends the fast. It opens the correction sheet, and the fast
//  keeps running until the sheet is confirmed — which is what makes a mis-tap
//  reversible without an undo, and what lets someone who forgot to stop say when
//  they actually ate.
//

import Foundation
import Redux

struct OpenEndFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard timer.isRunning, timer.fastStartTimestamp > 0 else { return }

        // One reading of the clock, and everything the four states branch on is
        // resolved from it. Read twice, the state the sheet opens in and the range it
        // clamps to could disagree by a second — and the one second that matters is
        // the one either side of the near-goal threshold.
        let now = Clock.now().timeIntervalSince1970
        let elapsed = max(0, now - timer.fastStartTimestamp)
        let goalSeconds = app.activeGoalHours * 3600
        let secondsLeft = goalSeconds - elapsed

        let entry: EndFastEntry
        let defaultEnd: Double
        if secondsLeft > 0 {
            // Whole minutes, rounded up: 15:00 left is 15 minutes and inside the
            // guard, 15:01 is 16 and outside it. Rounding down would put a fast
            // 15:59 short of its goal inside a guard that says "15 minutes left".
            let minutesLeft = Int(ceil(secondsLeft / 60))
            entry = minutesLeft <= EndFastState.nearGoalThresholdMinutes
                ? .nearGoal(minutesLeft: max(1, minutesLeft))
                : .ordinary
            defaultEnd = now
        } else if -secondsLeft >= EndFastState.overtimeNeutralThreshold {
            // Past the threshold the default stops being "just now": someone a day or
            // more past their goal is here to correct, and the moment they most
            // plausibly mean is the one the goal ran out on.
            entry = .overtime(secondsPastGoal: -secondsLeft)
            defaultEnd = timer.fastStartTimestamp + goalSeconds
        } else {
            entry = .ordinary
            defaultEnd = now
        }

        dispatch(EndFastAction.opened(
            entry: entry,
            endTimestamp: defaultEnd,
            fastStartTimestamp: timer.fastStartTimestamp,
            earliest: timer.fastStartTimestamp + EndFastState.minimumFastDuration,
            latest: now
        ))
    }
}
