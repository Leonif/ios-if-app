//
//  PhaseRing.swift
//  IFApp
//

import SwiftUI

struct PhaseRing: View {
    let progress: Double
    let currentPhase: Phase
    let isComplete: Bool
    let theme: ThemeTokens
    var diameter: CGFloat = 280
    var sealDiameter: CGFloat = 0
    var showsHeadDot: Bool = true

    private let lineWidth: CGFloat = 10
    private let sealClearance: CGFloat = 2

    private var centerRadius: CGFloat { diameter / 2 }

    private var sealGap: Double {
        guard sealDiameter > 0 else { return 0 }
        let halfExtent = sealDiameter / 2 + sealClearance + lineWidth / 2
        return asin(min(1, halfExtent / centerRadius)) / (2 * .pi)
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: sealGap, to: 1 - sealGap)
                .stroke(theme.ringTrack, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if isComplete {
                Circle()
                    .trim(from: sealGap, to: 1 - sealGap)
                    .stroke(loopedGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            } else {
                Circle()
                    .trim(from: 0, to: max(0.0001, progress))
                    .stroke(progressGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                if showsHeadDot { headDot }
            }
        }
        .frame(width: diameter, height: diameter)
        .environment(\.layoutDirection, .leftToRight)
        .animation(.easeOut(duration: 0.3), value: progress)
    }

    // MARK: - Gradients

    private var progressGradient: AngularGradient {
        let boundaries: [(Double, Phase)] = [(0, .fed), (0.25, .sugar), (0.5, .fat), (0.75, .ketosis)]
        var stops = boundaries
            .filter { $0.0 <= progress }
            .map { Gradient.Stop(color: $0.1.color, location: $0.0) }
        stops.append(Gradient.Stop(color: currentPhase.color, location: max(progress, 0.0001)))
        return AngularGradient(gradient: Gradient(stops: stops), center: .center)
    }

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

    // MARK: - Head dot

    private var headDot: some View {
        let theta = progress * 2 * .pi
        let x = centerRadius * sin(theta)
        let y = -centerRadius * cos(theta)
        return BreathingDot(color: currentPhase.color, isDark: theme.isDark)
            .offset(x: x, y: y)
            .animation(.easeOut(duration: 0.3), value: progress)
    }
}

private struct BreathingDot: View {
    let color: Color
    let isDark: Bool
    @State private var grown = false

    var body: some View {
        Circle()
            .fill(isDark ? Color(hex: "#0C0D10") : .white)
            .frame(width: 18, height: 18)
            .overlay(Circle().stroke(color, lineWidth: 3.5))
            .shadow(color: isDark ? color.opacity(0.6) : .clear, radius: 5)
            .scaleEffect(grown ? 1.22 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    grown = true
                }
            }
    }
}
