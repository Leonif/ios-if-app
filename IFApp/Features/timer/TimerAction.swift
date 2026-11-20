//
//  TimerAction.swift
//  IFApp
//

import Foundation
import Redux

enum TimerAction: Action {
    case started(startTimestamp: Double, goalHours: Double)
    case stopped(elapsed: TimeInterval, qualifiesAsCompleted: Bool, backdatedMinutes: Int)
    case stopUndone(startTimestamp: Double)
    case reset(elapsed: TimeInterval)
    case timeAdjusted(newElapsed: TimeInterval, runningStartTimestamp: Double?)
    case goalCelebrated(dayKey: String, ownsFreeze: Bool)
    case eatingStarted(startTimestamp: Double)
    case eatingEnded
    case startFastTapped
    case resumeTapped
    case resetTapped
    case startEatingTapped
    case continueFastingTapped
    case goalMomentStarted
}
