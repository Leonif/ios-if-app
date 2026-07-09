//
//  IFAppApp.swift
//  IFApp
//
//  Created by Leonid-user on 30.10.2024.
//

import SwiftUI
import Redux

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

@main
struct IFAppApp: App {
    @StateObject private var store: Store<AppState>

    init() {
        Self.configureFirebase()
        AppDependencies.register()
        let store = AppStoreFactory.make()
        _store = StateObject(wrappedValue: store)
        store.dispatch(ScheduleNotificationsThunk())
        store.dispatch(AppLifecycleAction.appOpened)
        if ProcessInfo.processInfo.arguments.contains("-showReviewPrompt") {
            store.dispatch(UIAction.reviewPromptOpened)
        }
    }

    /// Configures Firebase only when the SDK is linked AND GoogleService-Info.plist
    /// is bundled. Without the plist, `configure()` would crash — so we guard on it.
    private static func configureFirebase() {
        #if canImport(FirebaseCore)
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            print("[Analytics] GoogleService-Info.plist missing — Firebase not configured.")
            return
        }
        FirebaseApp.configure()
        tagInternalTraffic()
        #endif
    }

    /// Stamps every event from non-App-Store builds (Xcode DEBUG, simulator,
    /// TestFlight) with `traffic_type = internal`, so GA4's built-in Internal
    /// Traffic filter can exclude our own testing from the real-user reports.
    /// App Store production builds are left untagged.
    private static func tagInternalTraffic() {
        #if canImport(FirebaseAnalytics)
        guard isInternalBuild else { return }
        Analytics.setDefaultEventParameters(["traffic_type": "internal"])
        #endif
    }

    private static var isInternalBuild: Bool {
        #if DEBUG
        return true
        #else
        // TestFlight and sandbox builds carry a "sandboxReceipt"; App Store
        // production builds carry "receipt".
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppFlowView(store: store)
        }
    }
}
