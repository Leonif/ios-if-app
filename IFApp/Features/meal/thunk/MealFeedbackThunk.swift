//
//  MealFeedbackThunk.swift
//  IFApp
//

import UIKit
import Redux

enum MealScrubFeedback {
    case begin
    case step
    case edge
}

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
                Taptic.selection.prepare()
            case .edge:
                Taptic.edge.impactOccurred()
                Taptic.edge.prepare()
                let days = MealScale.maxMinutes / 1440
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "\(strings.Meal.daysAgo(days)). \(strings.Meal.scaleLimitNote)"
                )
            }
        }
    }
}
