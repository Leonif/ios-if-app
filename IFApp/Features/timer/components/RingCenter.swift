//
//  RingCenter.swift
//  IFApp
//
//  The three center states that sit inside the PhaseRing: idle (Start), active
//  (elapsed + phase), and complete (check + final duration).
//

import SwiftUI

/// "H:MM" from an elapsed interval (e.g. 13h24m -> "13:24").
private func hourMinute(_ elapsed: TimeInterval) -> String {
    let total = max(0, Int(elapsed))
    return String(format: "%d:%02d", total / 3600, (total / 60) % 60)
}

/// ":SS" seconds suffix for the live elapsed readout (e.g. ":07").
private func secondsSuffix(_ elapsed: TimeInterval) -> String {
    String(format: ":%02d", max(0, Int(elapsed)) % 60)
}

/// A small accent dot that softly pulses to signal a live, running fast.
private struct LiveDot: View {
    let color: Color
    @State private var dimmed = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .opacity(dimmed ? 0.32 : 1)
            .scaleEffect(dimmed ? 0.78 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    dimmed = true
                }
            }
    }
}

struct RingCenterIdle: View {
    let theme: ThemeTokens
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 26))
                Text(strings.Timer.start)
                    .font(.hanken(17, .bold))
            }
            .foregroundColor(theme.primaryButtonText)
            .frame(width: 154, height: 154)
            .background(Circle().fill(theme.primaryButtonBg))
            .shadow(color: theme.buttonShadow, radius: 18, x: 0, y: 16)
        }
        .buttonStyle(.pressable)
    }
}

struct RingCenterActive: View {
    let elapsed: TimeInterval
    let phase: Phase
    let theme: ThemeTokens

    /// Big H:MM with a small, dimmed :SS suffix in one baseline-aligned run, so the
    /// whole readout scales as a unit (via minimumScaleFactor) and never touches the
    /// ring on narrow devices or at two-digit hours.
    private var elapsedNumerals: AttributedString {
        var hm = AttributedString(hourMinute(elapsed))
        hm.font = Typography.timerNumerals
        hm.foregroundColor = theme.ink
        var ss = AttributedString(secondsSuffix(elapsed))
        ss.font = Typography.timerSeconds
        ss.foregroundColor = theme.mut
        return hm + ss
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                LiveDot(color: theme.accent)
                Text(strings.Timer.elapsedCaption)
                    .font(.hanken(12, .semibold))
                    .tracking(1.9)           // ~.16em at 12pt
                    .foregroundColor(theme.mut)
            }

            Text(elapsedNumerals)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 200)

            HStack(spacing: 7) {
                Circle()
                    .fill(phase.color)
                    .frame(width: 8, height: 8)
                Text(phase.label)
                    .font(.hanken(16, .semibold))
                    .foregroundColor(theme.ink)
            }
        }
    }
}

struct RingCenterComplete: View {
    let elapsed: TimeInterval
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(theme.primaryButtonBg)
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.primaryButtonText)
                )

            Text(strings.Timer.fastComplete)
                .font(.hanken(12, .semibold))
                .tracking(1.9)
                .foregroundColor(theme.mut)

            Text(hourMinute(elapsed))
                .font(Typography.completeNumerals)
                .monospacedDigit()
                .foregroundColor(theme.ink)
        }
    }
}
