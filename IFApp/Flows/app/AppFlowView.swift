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
        // The timer's centre is a fixed 232pt circle holding a fixed 176×40 caption
        // slot, and the footer buttons are fixed-width too. `Font.custom` scales with
        // the system text size, so past a point the text outgrows containers that do
        // not move: "Закривається о 20:00" clips to "Закриваєтьс…" inside the circle.
        // Capping here — one place, at the root — keeps every screen within the sizes
        // the layout was drawn for. The proper fix is a layout that stretches
        // (ScaledMetric on the slots); this ceiling holds the line until then.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}
