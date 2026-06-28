//
//  AnalyticsClient.swift
//  IFApp
//
//  The transport. Sends events to Firebase when the SDK is linked; otherwise
//  logs to the console so analytics work in dev/test builds without Firebase.
//

import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

protocol AnalyticsClient {
    func log(name: String, parameters: [String: Any])
}

struct DefaultAnalyticsClient: AnalyticsClient {
    func log(name: String, parameters: [String: Any]) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #else
        if parameters.isEmpty {
            print("[Analytics] \(name)")
        } else {
            print("[Analytics] \(name) \(parameters)")
        }
        #endif
    }
}
