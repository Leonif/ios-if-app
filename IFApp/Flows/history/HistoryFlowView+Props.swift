//
//  HistoryFlowView+Props.swift
//  IFApp
//

import Foundation

extension HistoryFlowView {
    struct Props: Equatable {
        let records: [FastRecord]
        let streak: StreakStatus
        let isRunning: Bool
        let isPro: Bool
        let exportFile: URL?
        let isExporting: Bool
        let isExportBusy: Bool

        init(state: AppState) {
            records = state.historyState.records
            streak = state.streak
            isRunning = state.timerState.isRunning
            isPro = state.proState.isPro
            exportFile = state.historyState.exportFile
            isExporting = state.historyState.isExporting
            isExportBusy = state.historyState.isExportBusy
        }
    }
}
