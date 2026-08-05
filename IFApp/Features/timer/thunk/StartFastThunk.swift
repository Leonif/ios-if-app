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

        let now = Date().timeIntervalSince1970
        // Carry any staged elapsed time into the start so the count continues from there.
        let startTimestamp = now - timer.stagedElapsed

        // Edge 9's second half. A custom length that is no longer paid for cannot be
        // started, but it also cannot be dropped silently: the person set seventeen
        // hours and would otherwise get sixteen with nothing said. The fast already
        // running when the right went away was left alone; this is the next one.
        let selected = app.planState.plan
        let plan = app.selectedPlanAllowed ? selected : selected.nearestPreset
        if plan != selected {
            dispatch(PlanAction.selected(hours: plan.hours))
            let notice = ProNotice.goalChanged(fallbackHours: plan.hours)
            // Queued but unsaid while the copy does not exist: consuming the flag now
            // would spend the one chance to say it on a blank sheet.
            if app.proState.goalChangePending, notice.hasCopy {
                dispatch(ProAction.noticeShown(notice))
            }
        }

        // The plan as it stands *now* becomes this fast's goal and stops moving.
        dispatch(TimerAction.started(startTimestamp: startTimestamp,
                                     goalHours: plan.fastHours))

        await requestPushAuthorizationIfNeeded(dispatch: dispatch)
    }

    /// Asks only while the status is `notDetermined`: the system shot is one-time,
    /// and on `denied` a repeat call shows nothing anyway. `push_status` is written
    /// from the status read back *after* the answer, so it reflects what the user
    /// actually chose (which may be partial), not what we asked for.
    private func requestPushAuthorizationIfNeeded(dispatch: @escaping (Action) -> Void) async {
        guard !Self.promptSuppressed else { return }
        guard await notifications.authorizationStatus() == .notDetermined else { return }

        await notifications.requestAuthorization()

        let status = await notifications.authorizationStatus()
        analytics.setUserProperty(SyncPushStatusThunk.label(for: status), forName: "push_status")
        dispatch(AppLifecycleAction.pushAuthorizationResolved)
    }

    /// UI tests drive Start fast, and the system dialog covers the screen and breaks
    /// the flow. `-suppressPushPrompt` skips the ask; DEBUG-only, like `UITestSeed`.
    private static var promptSuppressed: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-suppressPushPrompt")
        #else
        return false
        #endif
    }
}
