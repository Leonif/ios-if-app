//
//  GoalCelebration.swift
//  IFApp
//
//  The "goal reached" moment ("Seal & sweep") and the steady overtime glow that
//  follows it, drawn on top of the PhaseRing. A pure view: the parent owns the
//  animation values so the one-shot moment plays only on a genuine live crossing
//  and relaunching mid-overtime restores the settled end-state with no replay.
//

import SwiftUI

struct GoalMomentView: View {
    let sealScale: CGFloat      // 0 = hidden, 1 = full
    let haloOpacity: Double
    let sweepAngle: Double      // degrees, 0...360 during the sweep
    let sweepOpacity: Double
    let theme: ThemeTokens
    var diameter: CGFloat = 280

    private let lineWidth: CGFloat = 10
    private let sealDiameter: CGFloat = 44

    var body: some View {
        ZStack {
            halo.opacity(haloOpacity)
            sweep.opacity(sweepOpacity)
            seal.scaleEffect(sealScale).offset(y: -diameter / 2)
        }
        .frame(width: diameter, height: diameter)
        // Same pin as `PhaseRing` underneath, and for the same reason: the sweep is
        // placed by `rotationEffect`, whose angle RTL negates. Unpinned, the arc that
        // is meant to travel once around the ring from twelve o'clock started half a
        // turn away from the ring it is celebrating.
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
    }

    // Teal glow behind the ring — this is the "glowing ring" in the dark theme.
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

    // One bright arc that travels once around the ring band.
    private var sweep: some View {
        Circle()
            .trim(from: 0, to: 0.06)
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(-90 + sweepAngle))
    }

    // Green check seal at 12 o'clock, cut out from the spectrum by a background disc.
    private var seal: some View {
        ZStack {
            Circle()
                .fill(theme.backgroundBase)
                .frame(width: sealDiameter + 10, height: sealDiameter + 10)
            Circle()
                .fill(theme.primaryButtonBg)
                .frame(width: sealDiameter, height: sealDiameter)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.primaryButtonText)
                )
                .shadow(color: Phase.autophagy.color.opacity(0.5), radius: 9, x: 0, y: 6)
        }
    }
}
