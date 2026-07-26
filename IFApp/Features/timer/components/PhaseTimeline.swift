//
//  PhaseTimeline.swift
//  IFApp
//
//  Five equal columns: a bar over a track + a label. Current phase fills by its
//  real progress within the phase, passed 100%, future 0%. Labels recolor by state.
//

import SwiftUI

struct PhaseTimeline: View {
    let currentPhase: Phase
    /// Real progress through the current phase, 0...1.
    let currentFill: Double
    let isComplete: Bool
    let theme: ThemeTokens
    /// The history detail panel reuses the bars without their labels — there the
    /// phase is already named in the line above.
    var showsLabels: Bool = true

    private var currentIndex: Int { currentPhase.rawValue }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Phase.allCases, id: \.self) { phase in
                column(for: phase)
            }
        }
    }

    @ViewBuilder
    private func column(for phase: Phase) -> some View {
        let idx = phase.rawValue
        let fill: Double = {
            if isComplete { return 1 }
            if idx < currentIndex { return 1 }
            if idx == currentIndex { return min(1, max(0, currentFill)) }
            return 0
        }()
        let isCurrent = !isComplete && idx == currentIndex
        let isPassed = isComplete || idx < currentIndex

        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.isDark ? Color.whiteAlpha(0.08) : Color(hex: "#E7E5DE"))
                    Capsule().fill(phase.color)
                        .frame(width: geo.size.width * fill)
                }
            }
            .frame(height: 6)

            if showsLabels {
                Text(phase.label)
                    .font(.hanken(10.5, isCurrent ? .bold : .semibold))
                    .foregroundColor(isCurrent ? theme.deep : (isPassed ? theme.sec : theme.faint))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
