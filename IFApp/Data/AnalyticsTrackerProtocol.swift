//
//  AnalyticsTrackerProtocol.swift
//  IFApp
//

protocol AnalyticsTrackerProtocol {
    func log(_ event: AnalyticsEvent)
    func setUserProperty(_ value: String?, forName name: String)
}
