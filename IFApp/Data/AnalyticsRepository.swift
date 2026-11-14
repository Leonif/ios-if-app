//
//  AnalyticsRepository.swift
//  IFApp
//

protocol AnalyticsRepositoryProtocol {
    func log(_ event: AnalyticsEvent)
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
