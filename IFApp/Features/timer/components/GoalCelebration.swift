//
//  GoalCelebration.swift
//  IFApp
//

import SwiftUI

struct GoalMomentView: View {
    let sealScale: CGFloat
    let haloOpacity: Double
    let sweepAngle: Double
    let sweepOpacity: Double
    let theme: ThemeTokens
    var diameter: CGFloat = 280

    private let lineWidth: CGFloat = 10
    static let sealDiameter: CGFloat = 44

    var body: some View {
        ZStack {
            halo.opacity(haloOpacity)
            sweep.opacity(sweepOpacity)
            seal.scaleEffect(sealScale).offset(y: -diameter / 2)
        }
        .frame(width: diameter, height: diameter)
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
    }

    private var halo: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Phase.autophagy.color.opacity(0.9),
                        Phase.autophagy.color.opacity(0.25),
                        Phase.autophagy.color.opacity(0),
                    ],
                    center: .center,
                    startRadius: diameter * 0.30,
                    endRadius: diameter * 0.62
                )
            )
            .frame(width: diameter * 1.15, height: diameter * 1.15)
            .blur(radius: theme.isDark ? 26 : 20)
    }

    private var sweep: some View {
        Circle()
            .trim(from: 0, to: 0.06)
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(-90 + sweepAngle))
    }

    private var seal: some View {
        Circle()
            .fill(theme.primaryButtonBg)
            .frame(width: Self.sealDiameter, height: Self.sealDiameter)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.primaryButtonText)
            )
            .shadow(color: Phase.autophagy.color.opacity(0.5), radius: 9, x: 0, y: 6)
    }
}
