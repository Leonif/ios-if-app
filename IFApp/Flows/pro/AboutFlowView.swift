//
//  AboutFlowView.swift
//  IFApp
//

import Redux
import SwiftUI

struct AboutFlowView: View {
    private let store: Store<AppState>
    @State private var props: Props
    @Environment(\.openURL) private var openURL
    private let onSunnah: () -> Void

    init(store: Store<AppState>, onSunnah: @escaping () -> Void) {
        self.store = store
        self.onSunnah = onSunnah
        _props = State(initialValue: Props(state: store.getCurrentState()))
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
        .connect(to: store, mapState: { Props(state: $0) }, onPropsChange: { props = $0 })
    }
}
