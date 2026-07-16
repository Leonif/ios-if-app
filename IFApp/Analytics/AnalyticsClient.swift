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
    /// Sets a persistent user property for segmentation (nil clears it).
    func setUserProperty(_ value: String?, forName name: String)
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

    func setUserProperty(_ value: String?, forName name: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #else
        print("[Analytics] user_property \(name) = \(value ?? "nil")")
        #endif
    }
}
