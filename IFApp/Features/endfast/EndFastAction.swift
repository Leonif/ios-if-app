//
//  EndFastAction.swift
//  IFApp
//
//  Clock-dependent values are injected by thunks; the reducer stays pure. Every
//  action that moves the choice also carries `latest`, because "now" is the right
//  edge of the reachable range and it moves while the sheet is open.
//

import Redux

enum EndFastAction: Action {
    /// The sheet opened. Everything the four states branch on arrives here at once,
    /// resolved against a single reading of the clock.
    case opened(entry: EndFastEntry,
                endTimestamp: Double,
                fastStartTimestamp: Double,
                earliest: Double,
                latest: Double)
    /// A preset chip: an absolute moment, already resolved against the clock.
    case chipPicked(timestamp: Double, latest: Double)
    /// The exact-time control, ± minutes. Clamped into the reachable range.
    case timeStepped(byMinutes: Int, latest: Double)
    /// The chosen end overlaps a fast already saved. Carries the record itself so
    /// the reason can name it — a refusal that does not say what is in the way is
    /// the silent "no" this state exists to replace. `unavoidable` is true when the
    /// clash is on the fast's own start, so no choice of end can clear it and "pick
    /// another time" would only loop the person back to the same wall.
    case refused(conflict: FastRecord, unavoidable: Bool)
    /// "Pick another time": back to the picker with the previous choice intact.
    case refusalWithdrawn
    /// The sheet closed without ending the fast — the scrim, or `Keep this fast`.
    case closed
}
