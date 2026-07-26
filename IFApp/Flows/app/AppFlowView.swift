//
//  AppFlowView.swift
//  IFApp
//
//  Root flow. Owns the store and presents the current screen.
//

import SwiftUI
import Redux

struct AppFlowView: View {
    let store: Store<AppState>

    var body: some View {
        // The stack exists for the one push in the app — the history screen.
        NavigationStack {
            TimerFlowView(store: store)
        }
    }
}
