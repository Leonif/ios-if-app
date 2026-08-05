//
//  PaywallFlowView.swift
//  IFApp
//
//  The offer screen wired to the store. It owns nothing about how the offer looks —
//  that is `PaywallView` — only which of the six states is true right now and what
//  the four actions dispatch.
//
//  Motion is from the handoff and stated in numbers rather than left to taste: the
//  screen rises 28pt into place over 420ms with no overshoot, and the six states
//  cross-fade in 180ms without animating layout. A cross-fade cannot move the Buy
//  button under a thumb that is already travelling; a layout animation can.
//

import Redux
import SwiftUI

private struct PaywallProps: Equatable {
    let state: OfferState
    let price: String?
    let trigger: PaywallTrigger
    let showsNothingToRestore: Bool

    init(state: AppState) {
        self.state = state.proState.offerState
        price = state.proState.product?.displayPrice
        trigger = state.proState.trigger ?? .manual
        showsNothingToRestore = state.proState.showsNothingToRestore
    }
}

struct PaywallFlowView: View {
    private let store: Store<AppState>
    /// The phase the user came from. Passed in rather than derived here: it is the
    /// phase at the moment the offer was called, which is not necessarily the phase
    /// by the time they finish reading.
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
            // The warm scrim under the screen, so whatever called the offer does not
            // read through it while the card is still travelling.
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.18)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            PaywallView(
                state: props.state,
                price: props.price,
                trigger: props.trigger,
                phaseColor: phaseColor,
                theme: theme,
                showsNothingToRestore: props.showsNothingToRestore,
                onBuy: { store.dispatch(PurchaseProThunk()) },
                onRestore: { store.dispatch(RestorePurchasesThunk()) },
                onPrivacy: { openURL(Self.privacyURL) },
                onClose: { store.dispatch(ProAction.offerClosed) }
            )
            .id(props.state)
            .transition(.opacity)
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
        .connect(to: store, mapState: { PaywallProps(state: $0) }, onPropsChange: { props = $0 })
    }

    private static let privacyURL = URL(string: "https://leonif.github.io/if24-site/privacy.html")!
}
