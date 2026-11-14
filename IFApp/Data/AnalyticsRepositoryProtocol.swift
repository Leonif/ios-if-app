//
//  AnalyticsRepositoryProtocol.swift
//  IFApp
//

protocol AnalyticsRepositoryProtocol {
    func log(_ event: AnalyticsEvent)
    func setUserProperty(_ value: String?, forName name: String)
}
