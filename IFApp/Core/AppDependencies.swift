//
//  AppDependencies.swift
//  IFApp
//
//  Registers repositories in the container. Called once at app launch,
//  before the store is built or any thunk runs.
//

enum AppDependencies {
    static func register() {
        container.register(TimerPersistenceRepositoryProtocol.self) {
            TimerPersistenceRepository()
        }
        container.register(NotificationRepositoryProtocol.self) {
            NotificationRepository()
        }
        container.register(ReviewRepositoryProtocol.self) {
            ReviewRepository()
        }
        container.register(AnalyticsRepositoryProtocol.self) {
            AnalyticsRepository()
        }
    }
}
