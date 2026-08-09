//
//  AnalyticsRepository.swift
//  IFApp
//
//  Stateless gateway for emitting analytics events. Events are never logged from a
//  view: they come from AnalyticsMiddleware, which is the caller for everything that
//  travels as an action, and from the one failure that does not — `history_load_failed`
//  is found by the file layer, and wired to this gateway in `AppDependencies`.
//

protocol AnalyticsRepositoryProtocol {
    func log(_ event: AnalyticsEvent)
    /// Sets a persistent user property for segmentation (nil clears it).
    func setUserProperty(_ value: String?, forName name: String)
}

struct AnalyticsRepository: AnalyticsRepositoryProtocol {
    private let client: AnalyticsClient

    init(client: AnalyticsClient = DefaultAnalyticsClient()) {
        self.client = client
    }

    func log(_ event: AnalyticsEvent) {
        client.log(name: event.name, parameters: event.parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        client.setUserProperty(value, forName: name)
    }
}
