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
    /// Whether the offer is still up. Not rendered — it decides whether the rest of
    /// this struct is still worth applying. See `onPropsChange`.
    let isOpen: Bool
    let state: OfferState
    let price: String?
    let trigger: PaywallTrigger
    let showsNothingToRestore: Bool

    init(state: AppState) {
        isOpen = state.proState.isOfferOpen
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

            ZStack {
                // The card's own opaque surface, and it stays out here rather than
                // inside the view that carries the `.id`: a cross-fade stands both
                // layers at partial alpha in the middle, and a background that fades
                // with them is not a background. See `PaywallBackdrop`.
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
                // Both `zIndex`es are stated, and they are not decoration. Mid-swap the
                // stack briefly holds three children — the surface, the state going out
                // and the state coming in — and without an explicit order SwiftUI put
                // the outgoing one *under* the surface. It vanished on the first frame
                // instead of fading, so the card went blank for ~80ms in the middle of
                // a transition that is supposed to read as continuous.
                .zIndex(1)
            }
            // Surface and contents rise and arrive together — the 28pt of travel is
            // the card's, not the text's.
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
            // A screen on its way out keeps the state it was in. `purchaseCompleted`
            // clears the entry point and the purchase phase in one action, so the last
            // props to arrive would cross-fade `Confirming` back into `Buy` — and swap
            // the benefit order with the trigger, which also goes nil — underneath a
            // removal that is already running. The offer's own words, doubled, over the
            // screen behind them. Nothing said after the offer closes is addressed to
            // anyone: the card has a fifth of a second left and no reader.
            guard next.isOpen else { return }
            props = next
        })
    }
}
