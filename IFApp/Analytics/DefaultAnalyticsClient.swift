//
//  DefaultAnalyticsClient.swift
//  IFApp
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

struct DefaultAnalyticsClient: AnalyticsClient {
    private var isFirebaseConfigured: Bool {
        #if canImport(FirebaseCore)
        return FirebaseApp.app() != nil
        #else
        return false
        #endif
    }

    func log(name: String, parameters: [String: Any]) {
        #if canImport(FirebaseAnalytics)
        guard isFirebaseConfigured else { return }
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
        guard isFirebaseConfigured else { return }
        Analytics.setUserProperty(value, forName: name)
        #else
        print("[Analytics] user_property \(name) = \(value ?? "nil")")
        #endif
    }
}
