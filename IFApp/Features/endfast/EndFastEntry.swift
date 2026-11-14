//
//  EndFastEntry.swift
//  IFApp
//

import Foundation

enum EndFastEntry: Equatable, Sendable {
    case ordinary
    case nearGoal(minutesLeft: Int)
    case overtime(secondsPastGoal: TimeInterval)
}
