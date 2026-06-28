//
//  PhaseRing.swift
//  IFApp
//
//  The signature element: a 280pt ring whose progress arc is a smooth gradient of
//  every phase already passed, tipped by a head dot in the current phase color.
//  When complete, the gradient loops seamlessly through all five phases.
//

import SwiftUI

struct PhaseRing: View {
    let progress: Double        // 0...1 (fraction of the goal)
    let currentPhase: Phase
    let isComplete: Bool
    let theme: ThemeTokens

    private let diameter: CGFloat = 280
    private let lineWidth: CGFloat = 10

    private var centerRadius: CGFloat { (diameter - lineWidth) / 2 }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(theme.ringTrack, style: StrokeStyle(lineWidth: lineWidth))

            // Progress arc
            if isComplete {
                Circle()
                    .stroke(loopedGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            } else {
                Circle()
                    .trim(from: 0, to: max(0.0001, progress))
                    .stroke(progressGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                headDot
            }
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeOut(duration: 0.3), value: progress)
    }

    // MARK: Gradients

    /// Quarter-boundary stops up to the head, tipped with the current phase color.
    private var progressGradient: AngularGradient {
        let boundaries: [(Double, Phase)] = [(0, .fed), (0.25, .sugar), (0.5, .fat), (0.75, .ketosis)]
        var stops = boundaries
            .filter { $0.0 <= progress }
            .map { Gradient.Stop(color: $0.1.color, location: $0.0) }
        stops.append(Gradient.Stop(color: currentPhase.color, location: max(progress, 0.0001)))
        return AngularGradient(gradient: Gradient(stops: stops), center: .center)
    }

    /// Full-circle 6-stop loop so the seam at the top blends smoothly.
    private var loopedGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Phase.fed.color, location: 0.0),
                .init(color: Phase.sugar.color, location: 0.2),
                .init(color: Phase.fat.color, location: 0.4),
                .init(color: Phase.ketosis.color, location: 0.6),
                .init(color: Phase.autophagy.color, location: 0.8),
                .init(color: Phase.fed.color, location: 1.0),
            ]),
            center: .center
        )
    }

    // MARK: Head dot

    private var headDot: some View {
        let theta = progress * 2 * .pi
        let x = centerRadius * sin(theta)
        let y = -centerRadius * cos(theta)
        return Circle()
            .fill(theme.isDark ? Color(hex: "#0C0D10") : .white)
            .frame(width: 18, height: 18)
            .overlay(Circle().stroke(currentPhase.color, lineWidth: 3.5))
            .shadow(color: theme.isDark ? currentPhase.color.opacity(0.6) : .clear, radius: 5)
            .offset(x: x, y: y)
            .animation(.easeOut(duration: 0.3), value: progress)
    }
}
