//
//  LastMealPill.swift
//  IFApp
//
//  Idle entry to the log-meal flow. Shows the chosen last-meal value; when a past
//  time is chosen, a sub-line shows what the fast will count from.
//

import SwiftUI

struct LastMealPill: View {
    let valueText: String           // "Just now" or e.g. "7:00 PM"
    let subline: String?            // "Fast counts from 7:00 PM · 2h 40m in"
    let theme: ThemeTokens
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 15))
                        .foregroundColor(theme.iconStroke)
                    Text(strings.Timer.lastMeal)
                        .font(.hanken(13.5, .semibold))
                        .foregroundColor(theme.ink)
                    + Text(valueText)
                        .font(.hanken(13.5, .bold))
                        .foregroundColor(theme.deep)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.mut)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    Capsule().fill(theme.secBg)
                        .overlay(Capsule().stroke(theme.secLine, lineWidth: 1))
                        .shadow(color: theme.cardShadow, radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.pressable)

            if let subline {
                Text(subline)
                    .font(.hanken(12, .medium))
                    .foregroundColor(theme.mut)
            }
        }
    }
}
