//
//  PaywallFlowView+Props.swift
//  IFApp
//

extension PaywallFlowView {
    struct Props: Equatable {
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
}
