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
                // The plan name is context the ratio already carries: "16:8" plus the
                // pencil is the whole control, the name only says in words what the
                // numbers say. So when the header runs out of width — a narrow screen,
                // a large text size, and a locale whose name is long ("Tägliches
                // Fasten") all at once — the name steps aside rather than wrapping the
                // pill onto a second line or shrinking to a size the ratio beside it
                // contradicts. Measured per render, so a roomy header keeps the name.
                ViewThatFits(in: .horizontal) {
                    pill(withName: true)
                    pill(withName: false)
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

    /// One candidate row for the pill. `fixedSize` is what makes the choice honest:
    /// without it a candidate reports the width it could squeeze down to, and the
    /// wider one always "fits" — by breaking words.
    private func pill(withName: Bool) -> some View {
        HStack(spacing: 7) {
            Text(plan.ratioLabel)
                .font(.hanken(15, .bold))
                .monospacedDigit()
                .foregroundColor(theme.ink)
            if withName {
                Text(strings.Timer.dailyFast)
                    .font(.hanken(13, .medium))
                    .foregroundColor(theme.mut)
            }
            Image(systemName: "pencil")
                .font(.system(size: 13))
                .foregroundColor(theme.iconStroke)
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
}
