//
//  AppFlowView.swift
//  IFApp
//

import SwiftUI
import Redux

struct AppFlowView: View {
    let store: Store<AppState>

    @State private var props: Props
    @State private var offerTint: Color

    init(store: Store<AppState>) {
        self.store = store
        let state = store.getCurrentState()
        _props = State(initialValue: Props(state: state))
        _offerTint = State(initialValue: state.offerPhase(at: Date().timeIntervalSince1970).color)
    }

    var body: some View {
        NavigationStack {
            TimerFlowView(store: store)
        }
        .overlay {
            if props.offerOpen {
                PaywallFlowView(store: store, phaseColor: offerTint)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: props.offerOpen)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .connect(to: store, mapState: { Props(state: $0) }, onPropsChange: { next in
            if next.offerOpen && !props.offerOpen {
                offerTint = store.getCurrentState().offerPhase(at: Date().timeIntervalSince1970).color
            }
            props = next
        })
    }
}
