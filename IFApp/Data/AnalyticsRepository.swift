//
//  AnalyticsRepository.swift
//  IFApp
//
//  Stateless gateway for emitting analytics events. AnalyticsMiddleware is the
//  only caller — events are never logged directly from views.
//

protocol AnalyticsRepositoryProtocol {
    func log(_ event: AnalyticsEvent)
}

struct AnalyticsRepository: AnalyticsRepositoryProtocol {
    private let client: AnalyticsClient

    init(client: AnalyticsClient = DefaultAnalyticsClient()) {
        self.client = client
    }

    func log(_ event: AnalyticsEvent) {
        client.log(name: event.name, parameters: event.parameters)
    }
}
