//
//  EatingWindowCard.swift
//  IFApp
//
//  The eating-window center: a light countdown to when the next fast starts. No ring,
//  no phases — the window is a calm pause between fasts. Overline + H:MM:SS + caption.
//

import SwiftUI

/// "7:59:59" from a remaining interval (H:MM:SS).
private func hourMinuteSecond(_ remaining: TimeInterval) -> String {
    let total = max(0, Int(remaining))
    return String(format: "%d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
}

struct EatingWindowCard: View {
    let remaining: TimeInterval     // seconds until the window closes / fast starts
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 10) {
            Text(strings.Timer.eatingWindow)
                .font(.hanken(12, .semibold))
                .overlineTracking(1.9)
                .foregroundColor(theme.deep)

            Text(hourMinuteSecond(remaining))
                .font(Typography.completeNumerals)
                .monospacedDigit()
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(strings.Timer.fastStartsIn)
                .font(.hanken(14, .regular))
                .foregroundColor(theme.mut)
        }
        .frame(width: 232, height: 232)
        .background(
            Circle()
                .fill(theme.surface)
                .overlay(Circle().stroke(theme.surfaceLine, lineWidth: 1))
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: 10)
        )
    }
}
