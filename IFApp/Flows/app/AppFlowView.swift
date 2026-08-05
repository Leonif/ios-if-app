//
//  AppFlowView.swift
//  IFApp
//
//  Root flow. Owns the store, presents the current screen, and hosts the offer.
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
    /// The tint the offer wears, taken once — at the moment it opens. See
    /// `offerPhaseColor()`.
    @State private var offerTint: Color

    init(store: Store<AppState>) {
        self.store = store
        let state = store.getCurrentState()
        _props = State(initialValue: AppProps(state: state))
        _offerTint = State(initialValue: TimerScreenProps(state: state).offerPhaseColor())
    }

    var body: some View {
        // The stack exists for the one push in the app — the history screen.
        NavigationStack {
            TimerFlowView(store: store)
        }
        // The offer is a full surface rather than a `fullScreenCover` because its
        // appearance is specified in numbers — 28pt of travel over 420ms on a curve
        // with no overshoot — and the system cover brings its own.
        //
        // It is hosted here rather than on the timer because it now has two doors,
        // and the second one — the export lock — is on a screen pushed onto the
        // timer. An overlay on the timer renders under that push, so the offer would
        // open behind the screen it was called from, compile cleanly, and keep the
        // first door's tests green. The common ancestor of both entry points is the
        // only place where the z-order is right by construction rather than by code;
        // it also keeps the history alive underneath with its scroll position, which
        // is what closing the offer has to return to.
        .overlay {
            if props.offerOpen {
                PaywallFlowView(store: store, phaseColor: offerTint)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: props.offerOpen)
        // The timer's centre is a fixed 232pt circle holding a fixed 176×40 caption
        // slot, and the footer buttons are fixed-width too. `Font.custom` scales with
        // the system text size, so past a point the text outgrows containers that do
        // not move: "Закривається о 20:00" clips to "Закриваєтьс…" inside the circle.
        // Capping here — one place, at the root — keeps every screen within the sizes
        // the layout was drawn for. The proper fix is a layout that stretches
        // (ScaledMetric on the slots); this ceiling holds the line until then.
        //
        // The About sheet is presented, so it starts its own environment and this
        // ceiling does not reach it. That is deliberate: four locales overflow its Pro
        // row at xxLarge already, and the slots there are built to stretch.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .connect(to: store, mapState: { AppProps(state: $0) }, onPropsChange: { next in
            // The tint is read on the opening edge and held for as long as the offer
            // is up — see `offerPhaseColor()` for why it is frozen rather than live.
            if next.offerOpen && !props.offerOpen { offerTint = offerPhaseColor() }
            props = next
        })
    }

    /// The tint the offer inherits, from the one definition of it — the timer's own
    /// projection. It is a derivation on the view side and deliberately not an
    /// argument of `offerOpened`, which would put a clock reading into an action.
    ///
    /// Frozen at the moment the offer opens, on purpose: the value describes the
    /// phase of the screen the offer was called from, and that screen is fully
    /// covered while the offer is up, so there is nothing on display for a later
    /// tint to agree with. It also cannot honestly be a field of `AppProps` — the
    /// phase advances with the clock, not with the state, so a mapped prop would go
    /// stale between actions and then jump on an unrelated one. Held in `@State`
    /// instead, it changes at one named moment and nowhere else.
    private func offerPhaseColor() -> Color {
        TimerScreenProps(state: store.getCurrentState()).offerPhaseColor()
    }
}
