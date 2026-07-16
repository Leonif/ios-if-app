//
//  FooterCard.swift
//  IFApp
//
//  Active: three stats + "End fast". Complete: two stats + Reset / Start eating window.
//

import SwiftUI

/// A single stat column: overline + value.
private struct Stat: View {
    let overline: String
    let value: String
    var valueColor: Color
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 4) {
            Text(overline.uppercased())
                .font(.hanken(10.5, .semibold))
                .overlineTracking(1.4)
                .foregroundColor(theme.mut)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.hanken(15, .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CardBackground: ViewModifier {
    let theme: ThemeTokens
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.surfaceLine, lineWidth: 1))
                    .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
            )
    }
}

struct ActiveFooterCard: View {
    let startedAt: String       // "8:00 PM"
    let elapsed: String         // "13h 24m"
    let goalLabel: String       // "16h"
    let goalAt: String          // "12:00 PM"
    let theme: ThemeTokens
    let onEndFast: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Stat(overline: strings.Footer.started, value: startedAt, valueColor: theme.ink, theme: theme)
                divider
                Stat(overline: strings.Footer.elapsed, value: elapsed, valueColor: theme.deep, theme: theme)
                divider
                Stat(overline: strings.Footer.goal(goalLabel), value: goalAt, valueColor: theme.ink, theme: theme)
            }
            PrimaryButton(title: strings.Footer.endFast, theme: theme, action: onEndFast)
                .accessibilityIdentifier("timer.endFast")
        }
        .modifier(CardBackground(theme: theme))
    }

    private var divider: some View {
        Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
    }
}

/// Overtime footer: fasted / goal / over stats + Reset (secondary) and End fast (primary).
/// The fast is still running here — "End fast" ends it, "Reset" discards it (with a confirm).
struct GoalReachedFooterCard: View {
    let fasted: String          // "16h 24m"
    let goal: String            // "16h 00m"
    let over: String            // "+0:24"
    let theme: ThemeTokens
    let onReset: () -> Void
    let onEndFast: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Stat(overline: strings.Footer.fasted, value: fasted, valueColor: theme.ink, theme: theme)
                divider
                Stat(overline: strings.Footer.goalStat, value: goal, valueColor: theme.ink, theme: theme)
                divider
                Stat(overline: strings.Footer.over, value: over, valueColor: theme.deep, theme: theme)
            }
            HStack(spacing: 12) {
                SecondaryButton(title: strings.Footer.reset, theme: theme, action: onReset)
                    .frame(width: 110)
                    .accessibilityIdentifier("timer.reset")
                PrimaryButton(title: strings.Footer.endFast, theme: theme, action: onEndFast)
                    .accessibilityIdentifier("timer.endFast")
            }
        }
        .modifier(CardBackground(theme: theme))
    }

    private var divider: some View {
        Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
    }
}

struct CompleteFooterCard: View {
    let fasted: String          // "16h 02m"
    let windowOpens: String     // "Now"
    let theme: ThemeTokens
    let onReset: () -> Void
    let onStartEating: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Stat(overline: strings.Footer.fasted, value: fasted, valueColor: theme.deep, theme: theme)
                Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
                Stat(overline: strings.Footer.windowOpens, value: windowOpens, valueColor: theme.ink, theme: theme)
            }
            HStack(spacing: 12) {
                SecondaryButton(title: strings.Footer.reset, theme: theme, action: onReset)
                    .frame(width: 110)
                    .accessibilityIdentifier("timer.reset")
                PrimaryButton(title: strings.Footer.startEatingWindow, theme: theme, action: onStartEating)
            }
        }
        .modifier(CardBackground(theme: theme))
    }
}
