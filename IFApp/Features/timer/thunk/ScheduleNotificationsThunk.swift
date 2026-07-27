//
//  ScheduleNotificationsThunk.swift
//  IFApp
//
//  App-launch side effect: clear the legacy daily reminders. Authorization is no
//  longer requested here — it moved to the first Start fast (StartFastThunk), where
//  a push has a reason to exist for the user. The goal-reached push is managed by
//  NotificationMiddleware.
//

import Redux

struct ScheduleNotificationsThunk: Thunk {
    private let repo: NotificationRepositoryProtocol

    init(repo: NotificationRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        repo.removeLegacyDailyReminders()
    }
}
