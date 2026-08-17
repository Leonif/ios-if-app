//
//  MealFeedbackThunk.swift
//  IFApp
//
//  The ribbon's taptic feedback. The ribbon decides *whether* to ask (it owns the
//  velocity and the throttle); actually touching the taptic engine is a side effect,
//  so it happens here rather than in the view.
//

import UIKit
import Redux

enum MealScrubFeedback {
    /// A finger landed on the ribbon. Nothing to feel yet — this only warms the engine.
    case begin
    /// One snap step passed under the marker.
    case step
    /// The ribbon hit an end and stopped.
    case edge
}

/// The generators outlive a single tick on purpose. A freshly built generator has to
/// wake the taptic engine, which costs enough that the first click of a drag is late
/// or lost — the scrub then feels like silence followed by a rattle instead of an even
/// track. Keeping them alive and re-arming after every fire is what makes the ribbon
/// click like a system picker.
@MainActor
private enum Taptic {
    static let selection = UISelectionFeedbackGenerator()
    static let edge = UIImpactFeedbackGenerator(style: .rigid)
}

struct MealFeedbackThunk: Thunk {
    let kind: MealScrubFeedback

    init(_ kind: MealScrubFeedback) { self.kind = kind }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        await MainActor.run {
            switch kind {
            case .begin:
                Taptic.selection.prepare()
                Taptic.edge.prepare()
            case .step:
                Taptic.selection.selectionChanged()
                // Re-arm straight away: the next step is at most 45ms out.
                Taptic.selection.prepare()
            case .edge:
                Taptic.edge.impactOccurred()
                Taptic.edge.prepare()
                // The tick label at the end reads "7d"; a screen reader gets the
                // sentence, since it has no end-stop to feel.
                let days = MealScale.maxMinutes / 1440
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "\(strings.Meal.daysAgo(days)). \(strings.Meal.scaleLimitNote)"
                )
            }
        }
    }
}
