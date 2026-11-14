//
//  IFAppApp.swift
//  IFApp
//

import SwiftUI
import StoreKit
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
        if ProcessInfo.processInfo.arguments.contains("-showStreakMilestone") {
            store.dispatch(UIAction.streakMilestoneOpened)
        }
    }

    private static func configureFirebase() {
        #if canImport(FirebaseCore)
        guard !looksLikeMainlandChina else {
            print("[Analytics] Mainland China device — Firebase not configured.")
            return
        }
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

    private static var looksLikeMainlandChina: Bool {
        if SKPaymentQueue.default().storefront?.countryCode == "CHN" { return true }

        if Locale.current.region?.identifier == "CN" { return true }

        return Locale.preferredLanguages.contains(where: isSimplifiedChinese)
    }

    private static func isSimplifiedChinese(_ identifier: String) -> Bool {
        let language = Locale.Language(identifier: identifier)
        guard language.languageCode == .chinese else { return false }
        return language.script != .hanTraditional
    }

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
