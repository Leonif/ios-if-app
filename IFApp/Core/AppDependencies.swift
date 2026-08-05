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
        container.register(FastHistoryRepositoryProtocol.self) {
            FastHistoryRepository()
        }
        container.register(StoreRepositoryProtocol.self) {
            // StoreKit's local test configuration lives on the Xcode scheme, so an app
            // launched by `simctl` never has a store to talk to. `-seedStore` puts a
            // scripted one in its place; without the argument this is unreachable, and
            // outside DEBUG it does not exist.
            #if DEBUG
            if StubStoreRepository.isEnabled { return StubStoreRepository() }
            #endif
            return StoreRepository()
        }
    }
}
