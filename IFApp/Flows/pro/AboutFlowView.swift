//
//  AboutFlowView.swift
//  IFApp
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
            onOpenOffer: { store.dispatch(ProAction.offerOpened(trigger: .manual)) },
            onRestore: { store.dispatch(RestorePurchasesThunk()) },
            onPrivacy: { openURL(SiteLinks.privacyPolicy) },
            onSunnah: onSunnah,
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
