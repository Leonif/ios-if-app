//
//  NotificationRepository.swift
//  IFApp
//
//  Thin wrapper over NotificationManager so thunks depend on a protocol, not a singleton.
//

protocol NotificationRepositoryProtocol {
    func requestAuthorization()
    func scheduleDailyReminders()
}

struct NotificationRepository: NotificationRepositoryProtocol {
    func requestAuthorization() {
        NotificationManager.shared.requestAuthorization()
    }

    func scheduleDailyReminders() {
        NotificationManager.shared.scheduleDailyNoonNotification()
        NotificationManager.shared.scheduleDailyEveningNotification()
    }
}
