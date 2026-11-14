//
//  PhaseRingMini.swift
//  IFApp
//

import SwiftUI

struct PhaseRingMini: View {
    let record: FastRecord
    let theme: ThemeTokens

    private let diameter: CGFloat = 40
    private let outerSize: CGFloat = 32.8
    private let innerSize: CGFloat = 21.2

    private var fraction: Double { max(3.0 / 360.0, record.goalFraction) }

    var body: some View {
        let color = record.reachedPhase.color

        ZStack {
            Circle()
                .stroke(theme.ringTrack, lineWidth: 3.2)
                .frame(width: outerSize, height: outerSize)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: outerSize, height: outerSize)

            if record.isExtended {
                Circle()
                    .trim(from: 0, to: max(3.0 / 360.0, record.extendedFraction))
                    .stroke(color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: innerSize, height: innerSize)
            }
        }
        .frame(width: diameter, height: diameter)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}
