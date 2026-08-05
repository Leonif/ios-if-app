//
//  AboutFlowView.swift
//  IFApp
//
//  The About IF24 sheet wired to the store. Its only job beyond presentation is the
//  mapping from a three-valued entitlement plus an attempt in progress to the four
//  statuses the Pro row can say — and the rule that an unverified entitlement opens
//  the offer at S5 rather than at the offer itself.
//

import Redux
import SwiftUI

private struct AboutProps: Equatable {
    let status: ProRowStatus
    let showsNothingToRestore: Bool

    init(state: AppState) {
        let pro = state.proState
        if pro.phase == .awaitingApproval {
            status = .awaitingApproval
        } else {
            switch pro.entitlement {
            case .pro: status = .active
            case .free: status = .inactive
            // Never "inactive": we have not looked, and a lock is caution while a
            // status is a claim.
            case .unknown: status = .notCheckedYet
            }
        }
        showsNothingToRestore = pro.showsNothingToRestore
    }
}

struct AboutFlowView: View {
    private let store: Store<AppState>
    @State private var props: AboutProps
    @Environment(\.openURL) private var openURL

    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: AboutProps(state: store.getCurrentState()))
    }

    var body: some View {
        AboutIF24View(
            status: props.status,
            showsNothingToRestore: props.showsNothingToRestore,
            // The permanent entry. It reports `manual` whichever state the offer
            // opens in — the value names the door, not the frame behind it.
            onOpenOffer: { store.dispatch(ProAction.offerOpened(trigger: .manual)) },
            onRestore: { store.dispatch(RestorePurchasesThunk()) },
            onPrivacy: { openURL(Self.privacyURL) }
        )
        .animation(.easeInOut(duration: 0.18), value: props.showsNothingToRestore)
        .connect(to: store, mapState: { AboutProps(state: $0) }, onPropsChange: { props = $0 })
    }

    private static let privacyURL = URL(string: "https://leonif.github.io/if24-site/privacy.html")!
}
