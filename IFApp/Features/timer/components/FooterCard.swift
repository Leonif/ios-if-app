//
//  FooterCard.swift
//  IFApp
//

import SwiftUI

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
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.hanken(15, .bold))
                .foregroundColor(valueColor)
                .lineLimit(3)
                .multilineTextAlignment(.center)
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
    let startedAt: String
    let elapsed: String
    let goalLabel: String
    let goalAt: String
    let theme: ThemeTokens
    var isEndFastEnabled: Bool = true
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
                .endFastAvailability(isEndFastEnabled)
        }
        .modifier(CardBackground(theme: theme))
    }

    private var divider: some View {
        Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
    }
}

struct GoalReachedFooterCard: View {
    let fasted: String
    let goal: String
    let over: String
    let theme: ThemeTokens
    var isEndFastEnabled: Bool = true
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
            VStack(spacing: 12) {
                PrimaryButton(title: strings.Footer.endFast, theme: theme, action: onEndFast)
                    .accessibilityIdentifier("timer.endFast")
                    .endFastAvailability(isEndFastEnabled)
                SecondaryButton(title: strings.Footer.reset, theme: theme, action: onReset)
                    .accessibilityIdentifier("timer.reset")
            }
        }
        .modifier(CardBackground(theme: theme))
    }

    private var divider: some View {
        Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
    }
}

struct EatingFooterCard: View {
    let lastFast: String?
    let theme: ThemeTokens
    let onSkip: () -> Void
    let onStartFast: () -> Void
    let onHistory: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            if let lastFast {
                HistoryLink(title: strings.History.lastFast(lastFast), theme: theme,
                            identifier: "eating.lastFast", action: onHistory)
            }
            VStack(spacing: 12) {
                PrimaryButton(title: strings.Footer.startFast, theme: theme, action: onStartFast)
                    .accessibilityIdentifier("eating.startFast")
                TertiaryTextButton(title: strings.Footer.doneEating, theme: theme, action: onSkip)
                    .accessibilityIdentifier("eating.skip")
            }
        }
        .modifier(CardBackground(theme: theme))
    }
}

struct EatingOverFooterCard: View {
    let theme: ThemeTokens
    let onSkip: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: strings.Footer.continueFasting, theme: theme, action: onContinue)
                .accessibilityIdentifier("eatingOver.continueFasting")
            SecondaryButton(title: strings.Footer.notNowFast, theme: theme, action: onSkip)
                .accessibilityIdentifier("eatingOver.skip")
        }
        .modifier(CardBackground(theme: theme))
    }
}

struct CompleteFooterCard: View {
    let fasted: String
    let windowOpens: String
    let consequence: String
    let theme: ThemeTokens
    let onResume: () -> Void
    let onSkip: () -> Void
    let onStartEating: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Stat(overline: strings.Footer.fasted, value: fasted, valueColor: theme.deep, theme: theme)
                Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
                Stat(overline: strings.Footer.windowOpens, value: windowOpens, valueColor: theme.ink, theme: theme)
            }

            ConsequenceInset(text: consequence, theme: theme, identifier: "complete.consequence")

            QuietActionButton(title: strings.Complete.resumeFast, theme: theme, action: onResume)
                .accessibilityIdentifier("complete.resumeFast")

            VStack(spacing: 12) {
                PrimaryButton(title: strings.Footer.startEating, theme: theme, action: onStartEating)
                    .accessibilityIdentifier("timer.startEatingWindow")
                SecondaryButton(title: strings.Footer.declineWindow, theme: theme, action: onSkip)
                    .accessibilityIdentifier("timer.reset")
            }
        }
        .modifier(CardBackground(theme: theme))
    }
}

private extension View {
    func endFastAvailability(_ isEnabled: Bool) -> some View {
        disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.18), value: isEnabled)
    }
}
