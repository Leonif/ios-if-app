//
//  PhaseRingMini.swift
//  IFApp
//
//  The list's 40pt echo of the main ring. The arc fills to the fraction of the goal
//  the fast actually reached and takes the colour of the phase it ended in, so the
//  list shows the depth of each fast without a single chart. A fast past 24h draws
//  a second inner arc for the hours beyond the day.
//
//  Never mirrored in RTL: it is a progress indicator, and progress runs clockwise
//  from twelve o'clock in every locale.
//

import SwiftUI

struct PhaseRingMini: View {
    let record: FastRecord
    let theme: ThemeTokens

    private let diameter: CGFloat = 40
    private let outerSize: CGFloat = 32.8      // r = 16.4
    private let innerSize: CGFloat = 21.2      // r = 10.6

    /// A round cap on a near-zero arc renders as a bare dot; keep a 3° minimum so a
    /// very short fast still reads as an arc.
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
        .accessibilityHidden(true)
    }
}
