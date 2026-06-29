//
//  ScheduleNotificationsThunk.swift
//  IFApp
//
//  App-launch side effect: request notification authorization and clear the
//  legacy daily reminders. The goal-reached push is managed by NotificationMiddleware.
//

import Redux

struct ScheduleNotificationsThunk: Thunk {
    private let repo: NotificationRepositoryProtocol

    init(repo: NotificationRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        repo.requestAuthorization()
        repo.removeLegacyDailyReminders()
    }
}
