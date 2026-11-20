//
//  AnalyticsTracker.swift
//  IFApp
//

struct AnalyticsTracker: AnalyticsTrackerProtocol {
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
