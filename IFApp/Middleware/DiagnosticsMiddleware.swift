//
//  DiagnosticsMiddleware.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT

import Foundation
import Redux

final class DiagnosticsMiddleware: Middleware {
    private let log: DiagnosticsLoggerProtocol

    init(log: DiagnosticsLoggerProtocol = container.inject()) {
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
