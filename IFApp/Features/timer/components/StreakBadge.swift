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
//  there is room — the summary card and the VoiceOver label.
//
//  Three states, and not one of them carries a word. The pill used to read "History"
//  once the run broke, which changed its class from "my number" to a screen name, and
//  cost width the header does not have: the text budget on the rung that still carries
//  the Pro capsule is 72.0pt at the base size, and the shortest two-word candidate
//  about a streak runs 78pt in all ten locales. So a run that has just broken keeps
//  its number, drained of accent, and a pill with nothing to count carries the history
//  glyph instead — a signboard on the door, where the bare ring was a door without one
//  (S-2, F-3a). The glyph is a fixed 17pt box that Dynamic Type never grows, which is
//  what makes the state cost the same in every locale at every text size.
//

import SwiftUI

struct StreakBadge: View {
    /// The three states as one value, projected once in `StreakStatus.display(at:)`
    /// so this pill and the summary card cannot disagree about which one holds.
    let display: StreakDisplay
    let theme: ThemeTokens
    let onTap: () -> Void

    private static let milestones = [3, 7, 14, 30, 60]

    /// The number the state carries, 0 when the pill shows the glyph instead. Read off
    /// the projection rather than unwrapped here — one definition, two surfaces.
    private var days: Int { display.count }

    /// VoiceOver says in words what the pill is not allowed to spend width on: whether
    /// the number is a run in progress or the one that ended.
    private var accessibilityLabel: String {
        switch display {
        case .alive(let days): return strings.History.entryA11y(days)
        case .justEnded(let days): return strings.History.entryA11yLastStreak(days)
        case .none: return strings.History.entryA11yNoStreak
        }
    }

    /// Progress toward the next milestone; a streak past the last one stays full.
    private func progress(_ days: Int) -> Double {
        guard let next = Self.milestones.first(where: { $0 > days }) else { return 1 }
        let previous = Self.milestones.last(where: { $0 <= days }) ?? 0
        return Double(days - previous) / Double(next - previous)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if days > 0 {
                    ZStack {
                        Circle()
                            .stroke(theme.ringTrack, lineWidth: 2.2)
                        Circle()
                            .trim(from: 0, to: max(0.02, progress(days)))
                            // A run that has ended keeps its arc and loses the accent:
                            // `faint` on the usual track says "this was progress" without
                            // letting it read as progress still being made. The accent in
                            // this app means "your progress now", and lending it to a run
                            // that is over would be the app disagreeing with itself.
                            .stroke(display.hasEnded ? theme.faint : theme.accent,
                                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    // The 22pt slot holds an 18pt ring: the stroke is centred on that
                    // circle, so the ring reads 20.2pt across, as in the mockups.
                    .padding(2)
                    .frame(width: 22, height: 22)
                    // Pinned to the ring alone, not to the row: the counter beside it
                    // still follows the reading direction. RTL negates the `-90°` that
                    // starts the arc at twelve o'clock, which started the Arabic
                    // streak arc at six.
                    .environment(\.layoutDirection, .leftToRight)

                    // `Text("\(days)")` would take the LocalizedStringKey path and let
                    // the locale format the integer — Arabic-Indic "١" in the badge
                    // beside the Western digits of the history card one tap away.
                    // `String(_: Int)` is always Western, like every other number in
                    // the app. Same reason as `HistorySummaryCard`'s streak counter.
                    Text(verbatim: String(days))
                        .font(.hanken(13.5, .bold))
                        .monospacedDigit()
                        .foregroundColor(display.hasEnded ? theme.mut : theme.ink)
                } else {
                    // A clock face inside a counter-clockwise arc: time, turned back.
                    // Fixed at 17pt and never scaled by Dynamic Type — that constancy is
                    // the whole reason this state is free in every locale. It does not
                    // mirror in RTL (a clock runs clockwise everywhere, and a mirrored
                    // return arc reads as fast-forward); only the pill and the chevron do.
                    Image("history-arrow")
                        .renderingMode(.template)
                        .foregroundColor(theme.sec)
                        .frame(width: 17, height: 17)
                        // The ring's slot carries 2pt of its own padding, so the leading
                        // inset below is measured for it; the glyph has none and takes
                        // the difference here instead of widening the pill.
                        .padding(.leading, 4)
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
        .accessibilityLabel(accessibilityLabel)
    }
}
