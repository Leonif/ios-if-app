import SwiftUI
import UIKit
import Redux

struct SunnahFlowView: View {
    private let store: Store<AppState>
    @State private var props: SunnahState
    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: store.getCurrentState().sunnahState)
    }
    var body: some View {
        SunnahSettingsView(state: props,
            onChange: { store.dispatch(SunnahAction.settingsChanged($0)) },
            onRetry: { store.dispatch(SunnahAction.refresh) },
            onSettings: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    store.dispatch(OpenExternalLinkThunk(url: url))
                }
            })
            .onAppear { store.dispatch(SunnahAction.refresh) }
            .connect(to: store, mapState: { $0.sunnahState }, onPropsChange: { props = $0 })
    }
}
