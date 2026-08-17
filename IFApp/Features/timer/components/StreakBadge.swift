//
//  StreakBadge.swift
//  IFApp
//
//  The streak badge in the header, doubling as the way into the history. The two
//  are one thing seen from two sides: the badge is the streak compressed, the
//  history screen is the same streak unfolded. Tapping "12 days" answers the
//  question the badge provokes — "twelve days of what?" — so the app needs no
//  separate history tab, and stays a single-screen app.
//
//  The ring fills toward the next milestone (3/7/14/30/60); the chevron is the only
//  hint of navigation, which is all a pill this small can carry.
//
//  No unit word beside the number: pluralising a 12.5pt word across ten locales
//  (six categories in Arabic, four in Polish) is not worth one word. It stays where
//  there is room — the summary card and the VoiceOver label. A broken streak shows
//  the word "History" instead of a number, since "0 days" is not a thing.
//

import SwiftUI

struct StreakBadge: View {
    let days: Int
    let theme: ThemeTokens
    let onTap: () -> Void

    private static let milestones = [3, 7, 14, 30, 60]

    /// Progress toward the next milestone; a streak past the last one stays full.
    private var progress: Double {
        guard let next = Self.milestones.first(where: { $0 > days }) else { return 1 }
        let previous = Self.milestones.last(where: { $0 <= days }) ?? 0
        return Double(days - previous) / Double(next - previous)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                ZStack {
                    // A broken streak dims the track a step below its usual weight, so
                    // the empty ring reads as "nothing here yet" rather than "progress
                    // is zero". Dimming the track itself, not switching to a text token:
                    // `faint` is *darker* than the track and would shout instead.
                    Circle()
                        .stroke(days > 0 ? theme.ringTrack : theme.ringTrack.opacity(0.55), lineWidth: 2.2)
                    // The arc layer is absent, not zero-length: a round cap on a
                    // zero-length trim leaves a dot at 12 o'clock that reads as one day.
                    if days > 0 {
                        Circle()
                            .trim(from: 0, to: max(0.02, progress))
                            .stroke(theme.accent, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                }
                // The 22pt slot holds an 18pt ring: the stroke is centred on that
                // circle, so the ring reads 20.2pt across, as in the mockups.
                .padding(2)
                .frame(width: 22, height: 22)

                if days > 0 {
                    // `Text("\(days)")` would take the LocalizedStringKey path and let
                    // the locale format the integer — Arabic-Indic "١" in the badge
                    // beside the Western digits of the history card one tap away.
                    // `String(_: Int)` is always Western, like every other number in
                    // the app. Same reason as `HistorySummaryCard`'s streak counter.
                    Text(verbatim: String(days))
                        .font(.hanken(13.5, .bold))
                        .monospacedDigit()
                        .foregroundColor(theme.ink)
                } else {
                    Text(strings.History.title)
                        .font(.hanken(13, .semibold))
                        .foregroundColor(theme.ink)
                }
                Image(systemName: "chevron.forward")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(theme.mut)
            }
            // The ceiling, and the same pair `pill(withName:)` carries next door for
            // the same reason `TimerHeader` writes down there: inside a `ViewThatFits`
            // a candidate reports the width it could squeeze down to, so without this
            // the widest rung always "fits" and the badge pays for it afterwards. It
            // was paying — a 3-day streak on a 375pt screen rendered as a clipped digit
            // in en and as nothing at all in ar, leaving the bare ring and chevron that
            // F-3a is about, on the one control the header says yields nothing.
            //
            // Both halves are needed and neither is decorative: `lineLimit` stops the
            // word wrapping, `fixedSize` is what makes the reported width honest, so
            // the ladder drops the plan name — which the header already ranks as the
            // first thing to give — instead of crushing the badge. No scale factor
            // beside them, deliberately: yielding nothing means not shrinking either.
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(theme.secBg)
                    .overlay(Capsule().stroke(theme.secLine, lineWidth: 1))
            )
            // The pill itself is 34pt tall; the tap target is a full 44.
            .frame(height: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("streak.badge")
        .accessibilityLabel(days > 0 ? strings.History.entryA11y(days) : strings.History.entryA11yNoStreak)
    }
}
