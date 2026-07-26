//
//  TimerHeader.swift
//  IFApp
//
//  Top row on every state: plan pill (opens plan editor) + settings circle.
//

import SwiftUI

struct TimerHeader: View {
    let plan: Plan
    /// A broken streak still shows the pill (as "History"); zero records shows none.
    let streak: Int
    /// Whether there is any finished fast to look at.
    let hasRecords: Bool
    let theme: ThemeTokens
    let onEditPlan: () -> Void
    let onHistory: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onEditPlan) {
                HStack(spacing: 7) {
                    Text(plan.ratioLabel)
                        .font(.hanken(15, .bold))
                        .monospacedDigit()
                        .foregroundColor(theme.ink)
                    Text(strings.Timer.dailyFast)
                        .font(.hanken(13, .medium))
                        .foregroundColor(theme.mut)
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(theme.iconStroke)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(Capsule().fill(theme.iconCircle))
            }
            .buttonStyle(.pressable)

            Spacer(minLength: 8)

            // Nothing to open before the first fast lands: the pill appears with the
            // first record, a small opening rather than an empty promise.
            if hasRecords {
                StreakBadge(days: streak, theme: theme, onTap: onHistory)
            }

            Button(action: onSettings) {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundColor(theme.iconStroke)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(theme.iconCircle))
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("timer.sources")
        }
    }
}
