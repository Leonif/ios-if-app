//
//  EndFastState.swift
//  IFApp
//
//  The end-of-fast correction sheet's single source of truth. Mirror of the
//  last-meal picker, asking about the other end of the fast: not "when did the fast
//  start" but "when did it end" — which until now was always the moment of the tap,
//  with no control anywhere to say otherwise.
//

import Foundation

/// How the sheet was entered — the fact that decides which of the three picker
/// states is drawn.
///
/// Captured once, by the thunk that opens the sheet, rather than recomputed from the
/// clock while the sheet is up. The card must not change shape under the user's
/// finger: a fast 15:00 short of its goal is `nearGoal` for the whole time the sheet
/// is open, even though the minute rolls over while they read it. It is also what
/// keeps the clock out of the reducer (invariant 1) — every branch below is decided
/// from an injected payload.
enum EndFastEntry: Equatable, Sendable {
    /// Ordinary ending: the goal is either still far off, or passed recently enough
    /// that the app has nothing extra to say. State S1.
    case ordinary
    /// Near-goal guard: whole minutes left to the goal, 1...15. State S2.
    case nearGoal(minutesLeft: Int)
    /// Entered from overtime past the neutral-copy threshold — the person forgot to
    /// stop, and came here to correct rather than to confirm. State S3.
    case overtime(secondsPastGoal: TimeInterval)
}

/// Which of the four mutually exclusive cards is on screen. Derived, never stored:
/// two facts decide it (how the sheet was entered, and whether the current choice
/// collides with a saved fast), and a third copy of that decision is exactly how the
/// header came to sit over a body it no longer describes.
enum EndFastStage: Equatable, Sendable {
    case picker     // S1
    case nearGoal   // S2
    case overtime   // S3
    case refusal    // S4
}

struct EndFastState: Equatable, Sendable {
    /// Minutes left to the goal at or under which the near-goal state applies.
    /// Exactly 15 whole minutes: at 15:00 left the state is on, at 15:01 it is off.
    static let nearGoalThresholdMinutes = 15

    /// How far past the goal a fast has to run before the app stops encouraging and
    /// offers the correction instead. One constant, changed without re-laying out
    /// anything: the editorial copy on the main screen and this sheet's S3 both read
    /// it here.
    ///
    /// The sentence above was written as an intention and stood for a while as a
    /// falsehood: only S3 read the constant, and the main screen went on saying
    /// "every minute now is deeper autophagy" at hour 41 — the two surfaces of one
    /// fast disagreeing, with the sheet telling the truth and the screen behind it
    /// not. `TimerFlowView.editorial(state:progress:elapsed:)` reads it now, which is
    /// what makes the sentence true rather than aspirational.
    ///
    /// The quoted sentence is the pre-1.5.1 wording of `Editorial.goalReached` and is
    /// no longer in the catalog — grepping for it finds nothing. It is kept here as
    /// the shape of the bug, not as a string that exists.
    static let overtimeNeutralThreshold: TimeInterval = 24 * 3600

    /// The nearest a chosen end may come to the start of the fast. Below a minute
    /// apart the two are the same moment and the record is not a fast.
    static let minimumFastDuration: TimeInterval = 60

    /// Step of the exact-time control, in minutes.
    static let stepMinutes = 15

    var isOpen = false
    var entry: EndFastEntry = .ordinary
    /// The end moment under consideration, epoch seconds.
    var endTimestamp: Double = 0
    /// The start of the running fast, carried so the preview can name the duration
    /// the choice implies without the view reaching into another substate.
    var fastStartTimestamp: Double = 0
    /// The reachable range, injected at open and refreshed by every control that
    /// reads the clock. Nothing outside it is expressible: the future is not
    /// reachable, and neither is a moment before the fast began.
    var earliest: Double = 0
    var latest: Double = 0
    /// The saved fast the current choice collides with. Non-nil is the whole of the
    /// refusal state — there is no separate flag to disagree with it.
    var conflict: FastRecord?

    var stage: EndFastStage {
        if conflict != nil { return .refusal }
        switch entry {
        case .ordinary: return .picker
        case .nearGoal: return .nearGoal
        case .overtime: return .overtime
        }
    }

    /// Whether the exact-time control and its divider are drawn. They leave S2 and
    /// only S2: whoever pressed End fast that close to the goal is confirming a
    /// moment, not authoring one, and the height they free is what pays for the
    /// second action inside the sheet's budget. S3 is the state where the precision
    /// is the point, so it keeps them.
    var showsStepper: Bool { stage == .picker || stage == .overtime }

}
