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

struct RingCenterIdle: View {
    let theme: ThemeTokens
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 26))
                Text("Start")
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

    var body: some View {
        VStack(spacing: 6) {
            Text("ELAPSED")
                .font(.hanken(12, .semibold))
                .tracking(1.9)               // ~.16em at 12pt
                .foregroundColor(theme.mut)

            Text(hourMinute(elapsed))
                .font(Typography.timerNumerals)
                .monospacedDigit()
                .foregroundColor(theme.ink)

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

            Text("FAST COMPLETE")
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
