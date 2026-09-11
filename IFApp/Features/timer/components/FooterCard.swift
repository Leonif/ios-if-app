//
//  FooterCard.swift
//  IFApp
//
//  Active: three stats + "End fast". Complete: two stats + Resume / Skip / Start
//  eating window.
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
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.hanken(15, .bold))
                .foregroundColor(valueColor)
                // Wrapping, not a single clipped line. A column is an equal fraction of
                // the card width, and SwiftUI does not clip an overflowing `Text`: on one
                // line with a scale floor, a value too long for its fraction simply draws
                // across the hairline divider and into its neighbour. That is how de, ja
                // and ko rendered the overtime footer at the largest text size the app
                // allows as "16 Std 30 Min16 Std 00 Min" — two values, no gap, divider
                // buried underneath. pl and ar escaped it only by being shorter, which is
                // not a property to rely on: the next translation to grow brings it back.
                //
                // Lowering `minimumScaleFactor` instead would buy the fit by shrinking the
                // value below the size the reader asked for, which is the one thing a
                // raised text size is a request not to do. Wrapping costs nothing at the
                // sizes and lengths that already fit — the line count only changes where
                // the old layout was overflowing anyway.
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
    let startedAt: String       // "8:00 PM"
    let elapsed: String         // "13h 24m"
    let goalLabel: String       // "16h"
    let goalAt: String          // "12:00 PM"
    let theme: ThemeTokens
    /// False while the correction sheet this button opens is already up. The button
    /// stays on screen under the sheet's scrim, and left live it read as the way to
    /// confirm the ending — while a tap there is a tap outside the card, which closes
    /// the sheet. One control appearing to do the opposite of what it says.
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

/// Overtime footer: fasted / goal / over stats + Reset (secondary) and End fast (primary).
/// The fast is still running here — "End fast" ends it, "Reset" discards it (with a confirm).
struct GoalReachedFooterCard: View {
    let fasted: String          // "16h 24m"
    let goal: String            // "16h 00m"
    let over: String            // "+0:24"
    let theme: ThemeTokens
    /// See `ActiveFooterCard.isEndFastEnabled` — the same button, the same sheet.
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

/// Eating-window footer: Done (secondary, ends the window early) + Start fast (primary,
/// begins a new fast early). No stats — the countdown is the hero above, and it
/// already names the closing hour.
///
/// The window lasts hours, so it gets its own way into the history: the fast that
/// just closed is still "today's", and the link opens straight to it. `lastFast` is
/// nil only until the first record exists.
struct EatingFooterCard: View {
    let lastFast: String?       // "16h 24m"
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
                SecondaryButton(title: strings.Footer.doneEating, theme: theme, action: onSkip)
                    .accessibilityIdentifier("eating.skip")
            }
        }
        .modifier(CardBackground(theme: theme))
    }
}

/// Window-closed footer: Not now (secondary, back to idle) + Continue fasting (primary,
/// chains the next fast from the Last-meal time). No stats — the count-up is the hero.
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

/// The result card, mode C of the consequence genre: pinned above the home indicator,
/// outside the scroll. Every point it grows is taken from the scrolling middle, so the
/// budget is one sentence and nothing else may be added to it.
///
/// Two things changed against 1.5.0 and both are about rank. The card now *says* what
/// the two exits cost, in a slot that carries exactly one sentence — never none, never
/// two — and the undo is a control on the quiet material instead of the quietest text
/// on the card. The history row left the pinned zone altogether (it is drawn under the
/// phase scale in the scrolling middle): a navigation with no consequence was reading
/// as the final step of the stack, directly under the only reversible action.
struct CompleteFooterCard: View {
    let fasted: String          // "16h 02m"
    let windowOpens: String     // "Now"
    /// The single sentence of the mode-C slot, already arbitrated by the path the fast
    /// ended on. The card does not choose it: which of the two is true is a fact about
    /// the fast, not about the footer.
    let consequence: String
    let theme: ThemeTokens
    let onResume: () -> Void
    /// Back to idle without opening the window. Named for what it does — the button
    /// used to read "Reset", which in this state promises to discard a fast that is
    /// already written to the history.
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

            // The undo, on the same quiet material as the sentence that explains why it
            // exists: the warning and the way out are visibly one family. It is 50pt
            // tall against the 18pt of text it replaces — the only reversible control on
            // the card used to be the one thing on it below the HIG minimum, and rank
            // that rests on grey does not survive Arabic, where grey semibold reads
            // stronger than in Latin. Fill and height are locale-independent.
            //
            // No chevron — it goes nowhere. No lead-in ("Ended by mistake?"): that frames
            // the tap as a confession, and undo should read as an ordinary thing to want.
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
    /// The one place the unavailable look of `End fast` is spelled out, so the two
    /// footers that carry the button cannot drift apart on it. `.disabled` alone is
    /// invisible here: the button paints its own filled background, which no system
    /// style dims for it.
    func endFastAvailability(_ isEnabled: Bool) -> some View {
        disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.18), value: isEnabled)
    }
}
