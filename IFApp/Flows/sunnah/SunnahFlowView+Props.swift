//
//  SunnahFlowView+Props.swift
//  IFApp
//

extension SunnahFlowView {
    struct Props: Equatable {
        let state: SunnahState

        init(state: AppState) {
            self.state = state.sunnahState
        }
    }
}
