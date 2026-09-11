//
//  StartFastThunk.swift
//  IFApp
//
//  Reads the clock (a side effect) and dispatches a pure `.started` action, then
//  asks for notification permission — the first moment a push has a reason to
//  exist for the user. Both live in one thunk because the ask must follow the
//  start, and two thunks dispatched in a row are not ordered.
//

import Foundation
import Redux

struct StartFastThunk: Thunk {
    private let notifications: NotificationRepositoryProtocol
    private let analytics: AnalyticsRepositoryProtocol

    init(notifications: NotificationRepositoryProtocol = container.inject(),
         analytics: AnalyticsRepositoryProtocol = container.inject()) {
        self.notifications = notifications
        self.analytics = analytics
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard !timer.isRunning else { return }

        let startTimestamp = timer.startTimestamp(at: Date().timeIntervalSince1970)

        // Edge 9's second half. A custom length that is no longer paid for cannot be
        // started, but it also cannot be dropped silently: the person set seventeen
        // hours and would otherwise get sixteen with nothing said. The fast already
        // running when the right went away was left alone; this is the next one.
        let selected = app.planState.plan
        let plan = app.selectedPlanAllowed ? selected : selected.nearestPreset
        if plan != selected {
            dispatch(PlanAction.selected(hours: plan.hours))
            if app.proState.goalChangePending {
                dispatch(ProAction.noticeShown(.goalChanged(fallbackHours: plan.hours)))
            }
        }

        // The plan as it stands *now* becomes this fast's goal and stops moving.
        dispatch(TimerAction.started(startTimestamp: startTimestamp,
                                     goalHours: plan.fastHours))

        // The ask is `SyncPushStatusThunk.requestIfUndetermined`, shared with the
        // Sunnah opt-in, so both roads write `push_status` the same way.
        await SyncPushStatusThunk.requestIfUndetermined(notifications: notifications,
                                                        analytics: analytics,
                                                        dispatch: dispatch)
    }
}
