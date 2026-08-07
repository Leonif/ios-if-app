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
        store.dispatch(SyncPushStatusThunk())
        store.dispatch(AppLifecycleAction.appOpened)
        // UI tests force the streak milestone card open (pair with "-seedStreak N"
        // so the title shows a real day count).
        if ProcessInfo.processInfo.arguments.contains("-showStreakMilestone") {
            store.dispatch(UIAction.streakMilestoneOpened)
        }
    }

    /// Configures Firebase only when the SDK is linked AND the config plist is
    /// bundled. Without the plist, `configure()` would crash — so we guard on it.
    /// Internal builds point at a separate Firebase project ("IF24 Debug") so our
    /// own testing never lands in the production analytics.
    private static func configureFirebase() {
        #if canImport(FirebaseCore)
        let plistName = isInternalBuild ? "GoogleService-Info-Debug" : "GoogleService-Info"
        guard let plistPath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: plistPath) else {
            print("[Analytics] \(plistName).plist missing — Firebase not configured.")
            return
        }
        FirebaseApp.configure(options: options)
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
        // Only a positively identified App Store build counts as production;
        // anything else is ours. A locally built Release app also reports a
        // URL ending in "receipt" — but no file exists there, so the existence
        // check is what separates it from a real App Store install.
        // TestFlight carries a "sandboxReceipt" file and stays internal.
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path),
              receiptURL.lastPathComponent == "receipt"
        else { return true }
        return false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG || DEVELOPMENT
            AppFlowView(store: store).debugOverlay()
            #else
            AppFlowView(store: store)
            #endif
        }
    }
}
