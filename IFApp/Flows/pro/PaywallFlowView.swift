//
//  PaywallFlowView.swift
//  IFApp
//

import Redux
import SwiftUI

private struct PaywallProps: Equatable {
    let isOpen: Bool
    let state: OfferState
    let price: String?
    let trigger: PaywallTrigger
    let showsNothingToRestore: Bool

    init(state: AppState) {
        isOpen = state.proState.isOfferOpen
        self.state = state.proState.offerState
        price = state.proState.product?.displayPrice
        trigger = state.proState.trigger ?? .unknown
        showsNothingToRestore = state.proState.showsNothingToRestore
    }
}

struct PaywallFlowView: View {
    private let store: Store<AppState>
    private let phaseColor: Color

    @State private var props: PaywallProps
    @State private var appeared = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    init(store: Store<AppState>, phaseColor: Color) {
        self.store = store
        self.phaseColor = phaseColor
        _props = State(initialValue: PaywallProps(state: store.getCurrentState()))
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        ZStack {
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.18)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            ZStack {
                PaywallBackdrop(phaseColor: phaseColor, theme: theme)
                    .zIndex(0)

                PaywallView(
                    state: props.state,
                    price: props.price,
                    trigger: props.trigger,
                    theme: theme,
                    showsNothingToRestore: props.showsNothingToRestore,
                    onBuy: { store.dispatch(PurchaseProThunk()) },
                    onRestore: { store.dispatch(RestorePurchasesThunk()) },
                    onPrivacy: { openURL(SiteLinks.privacyPolicy) },
                    onClose: { store.dispatch(ProAction.offerClosed) }
                )
                .id(props.state)
                .transition(.opacity)
                .zIndex(1)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 28)
        }
        .animation(.easeInOut(duration: 0.18), value: props.state)
        .animation(.easeInOut(duration: 0.18), value: props.showsNothingToRestore)
        .onAppear {
            withAnimation(reduceMotion
                          ? .easeOut(duration: 0.24)
                          : .timingCurve(0.22, 0.8, 0.3, 1, duration: 0.42)) {
                appeared = true
            }
        }
        .connect(to: store, mapState: { PaywallProps(state: $0) }, onPropsChange: { next in
            guard next.isOpen else { return }
            props = next
        })
    }
}
