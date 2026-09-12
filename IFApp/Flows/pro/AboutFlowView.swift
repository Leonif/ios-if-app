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
    /// The Sunnah door, handed up rather than presented here. The reminders screen has
    /// two entries — the plan editor's row and this one — and an screen with more than
    /// one entry is presented from the nearest common ancestor of its entries
    /// (decision 05.08.2026), which is the timer: it already hosts this sheet and that
    /// one. Presented here it would have had a second host and a second flag, and the
    /// two doors would have disagreed about where closing the reminders screen lands.
    private let onSunnah: () -> Void

    init(store: Store<AppState>, onSunnah: @escaping () -> Void) {
        self.store = store
        self.onSunnah = onSunnah
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
            onPrivacy: { openURL(SiteLinks.privacyPolicy) },
            onSunnah: onSunnah,
            // The event is dispatched here rather than from the thunk: the same thunk
            // opens the privacy policy and the system Settings, and an event inside it
            // would report those as papers.
            onOpenSource: { articleID, url in
                store.dispatch(AppLifecycleAction.sourceOriginalOpened(articleID: articleID))
                store.dispatch(OpenExternalLinkThunk(url: url))
            },
            onOpenArticle: {
                store.dispatch(AppLifecycleAction.sourceArticleOpened(articleID: $0))
            },
            onCloseArticle: { articleID, reachedEnd in
                store.dispatch(AppLifecycleAction.sourceArticleClosed(articleID: articleID,
                                                                      reachedEnd: reachedEnd))
            }
        )
        .animation(.easeInOut(duration: 0.18), value: props.showsNothingToRestore)
        .connect(to: store, mapState: { AboutProps(state: $0) }, onPropsChange: { props = $0 })
    }
}
