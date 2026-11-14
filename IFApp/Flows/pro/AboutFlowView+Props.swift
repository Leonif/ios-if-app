//
//  AboutFlowView+Props.swift
//  IFApp
//

extension AboutFlowView {
    struct Props: Equatable {
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
}
