//
//  EatingWindowCard.swift
//  IFApp
//
//  The eating-window center: a light countdown to when the next fast starts. No ring,
//  no phases — the window is a calm pause between fasts. Overline + H:MM:SS + caption.
//  EatingOverCard reuses the same card for the window-closed count-up.
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
        WindowCard(overline: strings.Timer.eatingWindow,
                   value: hourMinuteSecond(remaining),
                   caption: strings.Timer.fastStartsIn,
                   theme: theme)
    }
}

/// The window-closed center: the same calm card, but counting UP since the window
/// closed — that time already belongs to the next fast once the user continues.
struct EatingOverCard: View {
    let sinceClose: TimeInterval    // seconds since the window closed
    let theme: ThemeTokens

    var body: some View {
        WindowCard(overline: strings.Timer.windowClosed,
                   value: hourMinuteSecond(sinceClose),
                   caption: strings.Timer.fastingSoFar,
                   theme: theme)
    }
}

/// Shared circular card: overline + H:MM:SS + caption over the pulsing halo.
private struct WindowCard: View {
    let overline: String
    let value: String
    let caption: String
    let theme: ThemeTokens
    @State private var haloDimmed = false

    var body: some View {
        VStack(spacing: 10) {
            Text(overline)
                .font(.hanken(12, .semibold))
                .overlineTracking(1.9)
                .foregroundColor(theme.deep)

            Text(value)
                .font(.bricolage(42))
                .monospacedDigit()
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(caption)
                .font(.hanken(14, .regular))
                .foregroundColor(theme.mut)
        }
        .frame(width: 232, height: 232)
        .background(
            ZStack {
                // Soft accent halo around the card, wider and dimmer than the drop shadow.
                // Pulses slowly like a heartbeat while the window is open.
                Circle()
                    .fill(theme.accent.opacity(theme.isDark ? 0.30 : 0.22))
                    .padding(-6)
                    .blur(radius: 26)
                    .scaleEffect(haloDimmed ? 0.96 : 1.07)
                    .opacity(haloDimmed ? 0.55 : 1)
                Circle()
                    .fill(theme.surface)
                    .overlay(Circle().stroke(theme.surfaceLine, lineWidth: 1))
                    .shadow(color: theme.cardShadow, radius: 24, x: 0, y: 10)
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                haloDimmed = true
            }
        }
    }
}
