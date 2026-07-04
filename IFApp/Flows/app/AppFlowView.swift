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
        TimerFlowView(store: store)
    }
}
