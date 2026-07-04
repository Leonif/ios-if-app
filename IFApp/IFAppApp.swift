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
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppFlowView(store: store)
        }
    }
}
