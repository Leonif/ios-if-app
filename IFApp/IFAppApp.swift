//
//  IFAppApp.swift
//  IFApp
//
//  Created by Leonid-user on 30.10.2024.
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
    /// On devices that look like mainland China we never configure Firebase at all
    /// — see `looksLikeMainlandChina`.
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

    /// True when any of three signals says the user is probably in mainland China:
    /// App Store storefront, device region, or preferred language.
    ///
    /// Why the gate exists: sending events to Firebase from mainland China is a
    /// cross-border transfer of personal information (个人信息保护法, art. 38-39),
    /// which needs separate consent (单独同意) plus a CAC mechanism. We have
    /// neither. Not configuring Firebase at all means there is no transfer and
    /// nothing to consent to — the gate therefore sits on `FirebaseApp.configure()`
    /// and not on event logging: a configured SDK registers the installation and
    /// talks to Google on its own, which is already the transfer.
    ///
    /// Why three signals OR'd together, and why that is deliberate: none of them
    /// proves physical presence, which is what PIPL art. 3(2) actually attaches to.
    /// Someone in Shanghai with a US Apple ID trips none of them; a Vancouver
    /// expat with device region CN trips all three. We take the **union** on
    /// purpose — a false positive costs us a few rows of analytics, a false
    /// negative is the violation. The "redundant" conditions are the point, so
    /// please do not simplify them away.
    ///
    /// Owner's decision of 10.08.2026, variant 2 of three (stay in the Chinese
    /// storefront, send nothing from it). Background and the acceptance criterion
    /// live in `obs-if24-wiki/privacy-label.md`, section (г).
    private static var looksLikeMainlandChina: Bool {
        // Storefront. StoreKit 2's `Storefront.current` is async, and this answer is
        // needed synchronously before `configureFirebase()` runs, so we read the
        // StoreKit 1 property. `nil` (store not reachable, or not resolved yet at
        // cold start) simply means this signal does not vote.
        if SKPaymentQueue.default().storefront?.countryCode == "CHN" { return true }

        if Locale.current.region?.identifier == "CN" { return true }

        return Locale.preferredLanguages.contains(where: isSimplifiedChinese)
    }

    /// Simplified Chinese in any spelling — `zh-Hans`, `zh-Hans-CN`, `zh-CN`, bare `zh`.
    /// Traditional Chinese is left out: Hong Kong, Taiwan and Macao are separate
    /// storefronts and PIPL does not reach them.
    private static func isSimplifiedChinese(_ identifier: String) -> Bool {
        let language = Locale.Language(identifier: identifier)
        guard language.languageCode == .chinese else { return false }
        return language.script != .hanTraditional
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
