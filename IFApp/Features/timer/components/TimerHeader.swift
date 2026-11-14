//
//  TimerHeader.swift
//  IFApp
//

import SwiftUI

struct TimerHeader: View {
    let plan: Plan
    let streak: StreakDisplay
    let hasRecords: Bool
    let showsPro: Bool
    let theme: ThemeTokens
    let onEditPlan: () -> Void
    let onHistory: () -> Void
    let onPro: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(withPlanName: true, withPencil: true, withPro: showsPro)
            row(withPlanName: false, withPencil: true, withPro: showsPro)
            row(withPlanName: false, withPencil: false, withPro: showsPro)
            row(withPlanName: false, withPencil: false, withPro: false)
        }
    }

    private func row(withPlanName: Bool, withPencil: Bool, withPro: Bool) -> some View {
        HStack(spacing: 8) {
            Button(action: onEditPlan) {
                pill(withName: withPlanName, withPencil: withPencil)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 13)
                    .background(Capsule().fill(theme.iconCircle))
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("timer.plan")

            Spacer(minLength: 8)

            if hasRecords || streak != .none {
                StreakBadge(display: streak, theme: theme, onTap: onHistory)
            }

            if withPro { proButton }

            Button(action: onSettings) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(theme.iconStroke)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(theme.iconCircle))
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("timer.sources")
        }
    }

    private var proButton: some View {
        Button(action: onPro) {
            Text(verbatim: "PRO")
                .font(.hanken(12, .semibold))
                .tracking(12 * 0.16)
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(Capsule().fill(theme.surfaceQuiet))
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("timer.pro")
        .accessibilityLabel(strings.Pro.productName)
        .accessibilityHint(strings.Pro.lockedDestinationHint)
    }

    private func pill(withName: Bool, withPencil: Bool) -> some View {
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
            if withPencil {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(theme.iconStroke)
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
}
