//
//  NextPhaseChip.swift
//  IFApp
//
//  Pill below the editorial, colored by the NEXT phase (handoff-derived colors).
//

import SwiftUI

struct NextPhaseChip: View {
    let next: Phase
    let secondsToNext: TimeInterval
    let theme: ThemeTokens

    var body: some View {
        let c = theme.chip(for: next.color)
        HStack(spacing: 7) {
            Circle()
                .fill(c.dot)
                .frame(width: 7, height: 7)
            Text(PhaseCopy.nextPhaseChip(next: next, secondsToNext: secondsToNext))
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
