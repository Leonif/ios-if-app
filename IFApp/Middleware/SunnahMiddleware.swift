import Foundation
import Redux
import UserNotifications
import UIKit

final class SunnahMiddleware: Middleware {
    private let repository: SunnahRepositoryProtocol
    private let notifications: NotificationSchedulerProtocol
    private var task: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    init(repository: SunnahRepositoryProtocol = container.inject(),
         notifications: NotificationSchedulerProtocol = container.inject()) {
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
        case let SunnahAction.systemSettingsTapped(url):
            dispatch(OpenExternalLinkThunk(url: url))
            return
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
            if requestPermission, await SyncPushStatusThunk.requestIfUndetermined(
                notifications: notifications, dispatch: { dispatch($0) }) {
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
            dispatch(SunnahAction.deliveryUpdated(
                delivery, dates: allowed ? reminders.prefix(3).map(\.fastDate) : []))
        }
    }
}
