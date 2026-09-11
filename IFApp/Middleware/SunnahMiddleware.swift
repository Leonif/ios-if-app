import Foundation
import Redux
import UserNotifications
import UIKit

/// Serial replacement prevents an older async scheduling pass from restoring cancelled reminders.
final class SunnahMiddleware: Middleware {
    private let repository: SunnahRepositoryProtocol
    private let notifications: NotificationRepositoryProtocol
    private let analytics: AnalyticsRepositoryProtocol
    private var task: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    init(repository: SunnahRepositoryProtocol = container.inject(),
         notifications: NotificationRepositoryProtocol = container.inject(),
         analytics: AnalyticsRepositoryProtocol = container.inject()) {
        self.repository = repository
        self.notifications = notifications
        self.analytics = analytics
    }
    deinit {
        task?.cancel()
        observers.forEach(NotificationCenter.default.removeObserver)
    }
    func handle<State: Equatable>(thunk: Thunk, state: State) {}
    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let app = state as? AppState else { return }
        if observers.isEmpty {
            for name in [Notification.Name.NSSystemTimeZoneDidChange, .NSCalendarDayChanged,
                         UIApplication.significantTimeChangeNotification] {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                    dispatch(SunnahAction.refresh)
                })
            }
        }
        var requestPermission = false
        switch action {
        case SunnahAction.settingsChanged:
            repository.save(app.sunnahState.settings)
            requestPermission = app.sunnahState.settings.enabled
        case SunnahAction.refresh, AppLifecycleAction.appOpened,
             AppLifecycleAction.appBecameActive, AppLifecycleAction.pushAuthorizationResolved:
            break
        default: return
        }
        let settings = app.sunnahState.settings
        let previous = task
        previous?.cancel()
        task = Task { [repository, notifications, analytics] in
            await previous?.value
            guard !Task.isCancelled else { return }
            // One ask for the whole app (see `requestIfUndetermined`). The resolved
            // action comes back through this middleware and schedules on the answer.
            if requestPermission, await SyncPushStatusThunk.requestIfUndetermined(
                notifications: notifications, analytics: analytics, dispatch: { dispatch($0) }) {
                return
            }
            let status = await notifications.authorizationStatus()
            guard !Task.isCancelled else { return }
            let allowed = [.authorized, .provisional, .ephemeral].contains(status)
            let reminders = SunnahSchedule.reminders(settings: settings, now: Clock.now(), timeZone: .current)
            let success = await repository.replace(allowed ? reminders : [])
            guard !Task.isCancelled else { return }
            let delivery = SunnahState.Delivery.resolve(
                enabled: settings.enabled, otherwise: !allowed ? .denied : (success ? .scheduled : .failed))
            // Upcoming dates are what *was scheduled*, not what the calendar holds.
            // With the permission refused nothing was written (`replace([])` above), so
            // the list would be a promise the app cannot keep — the loudest half of
            // SU-1, where the screen read as configured while no reminder could fire.
            dispatch(SunnahAction.deliveryUpdated(
                delivery, dates: allowed ? reminders.prefix(3).map(\.fastDate) : []))
        }
    }
}
