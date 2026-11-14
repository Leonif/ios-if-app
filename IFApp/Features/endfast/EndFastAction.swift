//
//  EndFastAction.swift
//  IFApp
//

import Redux

enum EndFastAction: Action {
    case opened(entry: EndFastEntry,
                endTimestamp: Double,
                fastStartTimestamp: Double,
                earliest: Double,
                latest: Double)
    case chipPicked(timestamp: Double, latest: Double)
    case timeStepped(byMinutes: Int, latest: Double)
    case refused(conflict: FastRecord, unavoidable: Bool)
    case refusalWithdrawn
    case closed
}
