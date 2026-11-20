//
//  StartFastThunk.swift
//  IFApp
//

import Foundation
import Redux

struct StartFastThunk: Thunk {
    private let notifications: NotificationSchedulerProtocol

    init(notifications: NotificationSchedulerProtocol = container.inject()) {
        self.notifications = notifications
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard !timer.isRunning else { return }

        let startTimestamp = timer.startTimestamp(at: Date().timeIntervalSince1970)

        let selected = app.planState.plan
        let plan = app.selectedPlanAllowed ? selected : selected.nearestPreset
        if plan != selected {
            dispatch(PlanAction.selected(hours: plan.hours))
            if app.proState.goalChangePending {
                dispatch(ProAction.noticeShown(.goalChanged(fallbackHours: plan.hours)))
            }
        }

        dispatch(TimerAction.started(startTimestamp: startTimestamp,
                                     goalHours: plan.fastHours))

        await SyncPushStatusThunk.requestIfUndetermined(notifications: notifications,
                                                        dispatch: dispatch)
    }
}
