import SwiftUI
import UIKit
import Redux

struct SunnahFlowView: View {
    private let store: Store<AppState>
    @State private var props: Props
    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: Props(state: store.getCurrentState()))
    }
    var body: some View {
        SunnahSettingsView(state: props.state,
            onChange: { store.dispatch(SunnahAction.settingsChanged($0)) },
            onRetry: { store.dispatch(SunnahAction.refresh) },
            onSettings: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    store.dispatch(OpenExternalLinkThunk(url: url))
                }
            })
            .onAppear { store.dispatch(SunnahAction.refresh) }
            .connect(to: store, mapState: { Props(state: $0) }, onPropsChange: { props = $0 })
    }
}
