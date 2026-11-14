//
//  TimerFlowView+Props.swift
//  IFApp
//

import Foundation

extension TimerFlowView {
    struct Props: Equatable {
        let timer: TimerState
        let activePlan: Plan
        let plan: Plan
        let minutesAgo: Int
        let chipIdx: Int
        let streak: StreakStatus
        let hasRecords: Bool
        let lastFastDuration: TimeInterval?
        let planEditorOpen: Bool
        let mealPickerOpen: Bool
        let streakMilestoneOpen: Bool
        let resetConfirmOpen: Bool
        let endEatingConfirmOpen: Bool
        let endFast: EndFastState
        let isPro: Bool
        let isVerifiedFree: Bool
        let offerOpen: Bool
        let notice: ProNotice?
        let revocationPending: Bool
        let autoOfferPending: Bool

        init(state: AppState) {
            timer = state.timerState
            activePlan = state.activePlan
            streak = state.streak
            hasRecords = !state.historyState.records.isEmpty
            lastFastDuration = state.historyState.records
                .max(by: { $0.endTimestamp < $1.endTimestamp })?
                .duration
            plan = state.planState.plan
            minutesAgo = state.mealState.minutesAgo
            chipIdx = state.mealState.chipIdx
            planEditorOpen = state.uiState.planEditorOpen
            mealPickerOpen = state.uiState.mealPickerOpen
            streakMilestoneOpen = state.uiState.streakMilestoneOpen
            resetConfirmOpen = state.uiState.resetConfirmOpen
            endEatingConfirmOpen = state.uiState.endEatingConfirmOpen
            endFast = state.endFastState
            isPro = state.proState.isPro
            isVerifiedFree = state.proState.isVerifiedFree
            offerOpen = state.proState.isOfferOpen
            notice = state.proState.notice
            revocationPending = state.proState.revocationPending
            autoOfferPending = state.proState.autoOfferPending
        }

        var isRunning: Bool { timer.isRunning }
        var fastStartTimestamp: Double { timer.fastStartTimestamp }
        var hasCelebrated: Bool { timer.hasCelebrated }
        var isEating: Bool { timer.isEating }
        var eatingEndTimestamp: Double { timer.eatingEndTimestamp(plan: activePlan) }
        var goalHours: Double { activePlan.fastHours }

        var isMealFresh: Bool { minutesAgo == 0 }

        func elapsed(at now: Date) -> TimeInterval {
            timer.elapsed(at: now.timeIntervalSince1970)
        }

        func eatingRemaining(at now: Date) -> TimeInterval {
            timer.eatingRemaining(at: now.timeIntervalSince1970, plan: activePlan)
        }

        func eatingOverElapsed(at now: Date) -> TimeInterval {
            timer.eatingOverElapsed(at: now.timeIntervalSince1970, plan: activePlan)
        }

        func screenState(at now: Date) -> TimerScreenState {
            timer.screenState(at: now.timeIntervalSince1970, plan: activePlan)
        }

        func currentScreenState() -> TimerScreenState {
            screenState(at: Date())
        }
    }
}
