//
//  AnalyticsClient.swift
//  IFApp
//

protocol AnalyticsClient {
    func log(name: String, parameters: [String: Any])
    func setUserProperty(_ value: String?, forName name: String)
}
