//
//  DiagnosticsMiddleware.swift
//  IFApp
//
//  Writes the action stream to the journal. Logging is a side effect, so it lives in a
//  middleware rather than in the store or the views (invariant 2), and it is the only
//  place that decides what a diagnostic line looks like.
//
//  It runs FIRST in the middleware list on purpose: if a later middleware throws or
//  wedges, the action that led there is already on disk.
//
//  Compiled out entirely outside DEBUG and DEVELOPMENT.
//

#if DEBUG || DEVELOPMENT

import Foundation
import Redux

final class DiagnosticsMiddleware: Middleware {
    private let log: DiagnosticsLogRepositoryProtocol

    init(log: DiagnosticsLogRepositoryProtocol = container.inject()) {
        self.log = log
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {
        log.append("thunk   \(type(of: thunk))")
    }

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let app = state as? AppState else {
            log.append("action  \(String(describing: action))")
            return
        }
        log.append("action  \(String(describing: action))")
        log.append("        \(Self.digest(app))")
    }

    /// The fields a failing flow is actually decided by, on one line.
    ///
    /// Deliberately not the whole `AppState`: a dump of every substate on every action
    /// is unreadable at the moment it is needed, and the history array alone would bury
    /// the sequence. What is here is what the state machine in `test-scenarios.md`
    /// branches on — whether a cycle is in flight, which goal it runs to, and what the
    /// entitlement machinery is doing.
    private static func digest(_ app: AppState) -> String {
        let timer = app.timerState
        var parts = [
            "run=\(timer.isRunning)",
            "eat=\(timer.isEating)",
            "goal=\(app.activeGoalHours)",
            "start=\(Int(timer.fastStartTimestamp))",
            "done=\(timer.completedSessionsCount)",
            "streak=\(timer.streakCount)",
            "plan=\(app.planState.plan.analyticsLabel)",
            "ent=\(app.proState.entitlement.rawValue)",
            "phase=\(String(describing: app.proState.phase))",
        ]
        if let trigger = app.proState.trigger { parts.append("offer=\(trigger.rawValue)") }
        if let product = app.proState.product { parts.append("price=\(product.displayPrice)") }
        return parts.joined(separator: " ")
    }
}

#endif
