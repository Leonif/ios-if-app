//
//  AppFlowView.swift
//  IFApp
//

import SwiftUI
import Redux

private struct AppProps: Equatable {
    let offerOpen: Bool

    init(state: AppState) {
        offerOpen = state.proState.isOfferOpen
    }
}

struct AppFlowView: View {
    let store: Store<AppState>

    @State private var props: AppProps
    @State private var offerTint: Color

    init(store: Store<AppState>) {
        self.store = store
        let state = store.getCurrentState()
        _props = State(initialValue: AppProps(state: state))
        _offerTint = State(initialValue: TimerScreenProps(state: state).offerPhaseColor())
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
        .connect(to: store, mapState: { AppProps(state: $0) }, onPropsChange: { next in
            if next.offerOpen && !props.offerOpen { offerTint = offerPhaseColor() }
            props = next
        })
    }

    private func offerPhaseColor() -> Color {
        TimerScreenProps(state: store.getCurrentState()).offerPhaseColor()
    }
}
