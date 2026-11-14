//
//  AppDependencies.swift
//  IFApp
//

enum AppDependencies {
    static func register() {
        container.register(SunnahRepositoryProtocol.self) { SunnahRepository() }
        container.register(ExternalLinkRepositoryProtocol.self) {
            ExternalLinkRepository()
        }
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
            #if DEBUG
            if StubStoreRepository.isEnabled { return StubStoreRepository() }
            #endif
            return StoreRepository()
        }
        #if DEBUG || DEVELOPMENT
        let diagnostics = DiagnosticsLogRepository()
        container.register(DiagnosticsLogRepositoryProtocol.self) { diagnostics }
        #endif
    }
}
