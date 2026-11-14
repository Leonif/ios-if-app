//
//  HistoryEmptyAction.swift
//  IFApp
//

enum HistoryEmptyAction {
    case startFast
    case backToFast

    var title: String {
        switch self {
        case .startFast: return strings.History.emptyCta
        case .backToFast: return strings.History.emptyBackToFast
        }
    }

    var identifier: String {
        switch self {
        case .startFast: return "history.startFast"
        case .backToFast: return "history.empty.backToFast"
        }
    }
}
