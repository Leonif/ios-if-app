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
            // The repository finds the failure; that a failure is worth an analytics
            // event is decided here, in the composition root, so the file layer stays
            // ignorant of the event catalog. The analytics repository is resolved on
            // the call rather than captured — registration order then does not matter.
            FastHistoryRepository { reason in
                let analytics: AnalyticsRepositoryProtocol = container.inject()
                analytics.log(.historyLoadFailed(reason: reason.rawValue))
            }
        }
        container.register(ProOfferRepositoryProtocol.self) {
            ProOfferRepository()
        }
        container.register(HistoryExportRepositoryProtocol.self) {
            HistoryExportRepository()
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
        #if DEBUG || DEVELOPMENT
        // One shared instance, unlike every other registration here. The journal owns
        // an open `FileHandle` positioned at the end of the file; a second instance
        // would open its own handle at the same offset and the two would write over
        // each other's lines. A second reader of this protocol appeared with the seed
        // collision warning (UITestSeed), which is when that stopped being theoretical.
        let diagnostics = DiagnosticsLogRepository()
        container.register(DiagnosticsLogRepositoryProtocol.self) { diagnostics }
        #endif
    }
}
