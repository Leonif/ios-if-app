//
//  ScheduleNotificationsThunk.swift
//  IFApp
//
//  App-launch side effect: request notification authorization and schedule
//  the daily reminders. Replaces the old onAppear/NotificationManager calls.
//

import Redux

struct ScheduleNotificationsThunk: Thunk {
    private let repo: NotificationRepositoryProtocol

    init(repo: NotificationRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        repo.requestAuthorization()
        repo.scheduleDailyReminders()
    }
}
