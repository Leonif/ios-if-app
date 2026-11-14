//
//  AppFlowView+Props.swift
//  IFApp
//

extension AppFlowView {
    struct Props: Equatable {
        let offerOpen: Bool

        init(state: AppState) {
            offerOpen = state.proState.isOfferOpen
        }
    }
}
