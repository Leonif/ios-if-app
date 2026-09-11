import Foundation
import Redux
import UserNotifications
import UIKit

/// Serial replacement prevents an older async scheduling pass from restoring cancelled reminders.
final class SunnahMiddleware: Middleware {
    private let repository: SunnahRepositoryProtocol
    private let notifications: NotificationRepositoryProtocol
    private var task: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    init(repository: SunnahRepositoryProtocol = container.inject(),
         notifications: NotificationRepositoryProtocol = container.inject()) {
        self.repository = repository
        self.notifications = notifications
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
        task = Task { [repository, notifications] in
            await previous?.value
            guard !Task.isCancelled else { return }
            let before = await notifications.authorizationStatus()
            if requestPermission && before == .notDetermined {
                await notifications.requestAuthorization()
                // The existing goal/eating push may have been rejected before this grant.
                dispatch(AppLifecycleAction.pushAuthorizationResolved)
                return
            }
            let status = await notifications.authorizationStatus()
            guard !Task.isCancelled else { return }
            let allowed = [.authorized, .provisional, .ephemeral].contains(status)
            let reminders = SunnahSchedule.reminders(settings: settings, now: Clock.now(), timeZone: .current)
            let success = await repository.replace(allowed ? reminders : [])
            guard !Task.isCancelled else { return }
            let delivery: SunnahState.Delivery = !settings.enabled ? .off :
                (!allowed ? .denied : (success ? .scheduled : .failed))
            dispatch(SunnahAction.deliveryUpdated(delivery, dates: reminders.prefix(3).map(\.fastDate)))
        }
    }
}
