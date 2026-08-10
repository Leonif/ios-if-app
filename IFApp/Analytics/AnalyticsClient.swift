//
//  AnalyticsClient.swift
//  IFApp
//
//  The transport. Sends events to Firebase when the SDK is linked; otherwise
//  logs to the console so analytics work in dev/test builds without Firebase.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

protocol AnalyticsClient {
    func log(name: String, parameters: [String: Any])
    /// Sets a persistent user property for segmentation (nil clears it).
    func setUserProperty(_ value: String?, forName name: String)
}

struct DefaultAnalyticsClient: AnalyticsClient {
    /// Firebase is deliberately left unconfigured on mainland-China devices, and on
    /// any build without the config plist (`IFAppApp.configureFirebase()`). Every
    /// event then drops here, silently — the rest of the app keeps working.
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
