//
//  NextPhaseChip.swift
//  IFApp
//

import SwiftUI

struct NextPhaseChip: View {
    let next: Phase
    let secondsToNext: TimeInterval
    let theme: ThemeTokens

    var body: some View {
        PhaseChipShape(
            color: next.color,
            text: PhaseCopy.nextPhaseChip(next: next, secondsToNext: secondsToNext),
            theme: theme
        )
    }
}

struct StaticPhaseChip: View {
    let phase: Phase
    let text: String
    let theme: ThemeTokens

    var body: some View {
        PhaseChipShape(color: phase.color, text: text, theme: theme)
    }
}

private struct PhaseChipShape: View {
    let color: Color
    let text: String
    let theme: ThemeTokens

    var body: some View {
        let c = theme.chip(for: color)
        HStack(spacing: 7) {
            Circle()
                .fill(c.dot)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.hanken(13, .semibold))
                .foregroundColor(c.text)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 13)
        .background(
            Capsule().fill(c.bg).overlay(Capsule().stroke(c.border, lineWidth: 1))
        )
    }
}
