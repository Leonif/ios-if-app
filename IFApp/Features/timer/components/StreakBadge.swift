//
//  StreakBadge.swift
//  IFApp
//
//  Small flame pill on the main screen: "N-day streak". Shown on the idle and
//  active states once the streak is at least 2 days. No animation — a quiet
//  daily reason to come back, not a celebration.
//

import SwiftUI

struct StreakBadge: View {
    let days: Int
    let theme: ThemeTokens

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.accent)
            Text(strings.Streak.badge(days))
                .font(.hanken(13, .semibold))
                .foregroundColor(theme.deep)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 13)
        .background(
            Capsule().fill(theme.surface).overlay(Capsule().stroke(theme.surfaceLine, lineWidth: 1))
        )
        .accessibilityIdentifier("streak.badge")
    }
}
