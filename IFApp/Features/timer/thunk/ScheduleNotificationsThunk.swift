//
//  ScheduleNotificationsThunk.swift
//  IFApp
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
