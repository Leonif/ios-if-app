//
//  TimerHeader.swift
//  IFApp
//
//  Top row on every state: plan pill (opens plan editor) + streak badge + the Pro
//  entry + settings circle.
//

import SwiftUI

struct TimerHeader: View {
    let plan: Plan
    /// The streak as the pill draws it — live number, the number a broken run left
    /// behind, or nothing to count. No records and nothing to count shows no pill.
    let streak: StreakDisplay
    /// Whether there is any finished fast to look at.
    let hasRecords: Bool
    /// The permanent door into the offer. Whether it belongs on screen at all is
    /// decided by the flow (a verified `free` entitlement, and not in the goal
    /// moment) — the header only lays it out and gives it up first when the row
    /// runs out of width.
    let showsPro: Bool
    let theme: ThemeTokens
    let onEditPlan: () -> Void
    let onHistory: () -> Void
    let onPro: () -> Void
    let onSettings: () -> Void

    var body: some View {
        // The order things give way in, and it is a decision rather than a
        // convenience: the plan name goes first (the ratio beside it already says
        // what it says), then the pencil, then the Pro control leaves the row whole,
        // and the streak badge yields nothing — not its word, not its presence. A
        // badge stripped down to a bare ring with a chevron is a finding the wiki
        // already has (F-3a); reproducing it at accessibility text sizes to keep a
        // control that was just added would be fixing one thing by breaking its
        // neighbour.
        //
        // The pencil rung exists because the row above it had no slack left. At
        // 375pt, the largest type and the longest of the ten History words
        // ("Historique"), it asks for every point it has — 327 of 327, about one
        // point in hand — and the fifth glyph of the ratio costs one tabular digit.
        // Measured on the running app the pill goes 79.5pt → 89.5pt, so `14:10` (and
        // any custom goal of 10-14 hours) overran and fell straight past the Pro
        // control to the last rung.
        //
        // Dropping the pencil takes the pill to 69pt: 20.5pt freed, 10.5pt of it
        // left over after the overrun is paid. Squeezing the pill's horizontal
        // padding from 13 to 8 was the other candidate and was tried on the device:
        // it frees exactly 10pt and renders a 79.5pt pill — the same width, and so
        // the same 327-of-327 row, that this bug was found sitting on. It buys the
        // fix by moving back onto the edge it fell off, and pays for it in a spacing
        // value the mockups pin.
        //
        // The Pro control is not a rung to spend on a hair's width: it exists
        // because of an Apple rejection, and it is what raises the event for
        // entering the offer from the main screen, so no locale may reach a row
        // without it while there is anything cheaper left to give.
        //
        // Measured on whole rows rather than per control: a nested `ViewThatFits`
        // inside the pill is measured with an unspecified width and so always
        // reports its widest candidate, which would drop the Pro control *before*
        // the plan name — the ladder upside down.
        ViewThatFits(in: .horizontal) {
            row(withPlanName: true, withPencil: true, withPro: showsPro)
            row(withPlanName: false, withPencil: true, withPro: showsPro)
            row(withPlanName: false, withPencil: false, withPro: showsPro)
            // Last rung. With `showsPro == false` this repeats the one above, which
            // is what makes the ladder one list instead of two branches: a
            // conditional inside `ViewThatFits` collapses into a single candidate.
            row(withPlanName: false, withPencil: false, withPro: false)
        }
    }

    private func row(withPlanName: Bool, withPencil: Bool, withPro: Bool) -> some View {
        HStack(spacing: 8) {
            Button(action: onEditPlan) {
                // The plan name is context the ratio already carries: "16:8" plus the
                // pencil is the whole control, the name only says in words what the
                // numbers say. So when the header runs out of width — a narrow screen,
                // a large text size, and a locale whose name is long ("Tägliches
                // Fasten") all at once — the name steps aside rather than wrapping the
                // pill onto a second line or shrinking to a size the ratio beside it
                // contradicts. Measured per render, so a roomy header keeps the name.
                pill(withName: withPlanName, withPencil: withPencil)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 13)
                    .background(Capsule().fill(theme.iconCircle))
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("timer.plan")

            Spacer(minLength: 8)

            // Nothing to open before the first fast lands: the pill appears with the
            // first record, a small opening rather than an empty promise. A live streak
            // counts as something to open too — emptying the history mid-fast used to
            // shut the door for the rest of the fast, and the app then spent ~10 hours
            // telling someone on a two-day run that they had no streak.
            if hasRecords || streak != .none {
                StreakBadge(display: streak, theme: theme, onTap: onHistory)
            }

            if withPro { proButton }

            // The sheet behind this is no longer a science note but the app's own
            // document — Pro, privacy, sources. `doc.text` promised a paper;
            // `info.circle` is the only glyph of the three considered that says
            // "about this app" without also promising a menu that does not exist.
            Button(action: onSettings) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(theme.iconStroke)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(theme.iconCircle))
                    // The circle stays 34pt and the target becomes 44, the way the
                    // streak badge already does it. Below the HIG minimum it got away
                    // with it while its nearest neighbour was a Spacer away; with a
                    // second small control right beside it, an occasional near miss
                    // becomes a systematic one that lands on the wrong control (F-4).
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("timer.sources")
        }
    }

    /// The permanent way into the offer, and deliberately furniture rather than a
    /// shopfront: no icon, no gradient, and not the accent colour — the accent in this
    /// app means "your progress" (the ring, the seal, the halo), and lending it to the
    /// one commercial element would paint selling in the colour of achievement.
    ///
    /// It is told apart from its three filled neighbours by material and by word, not
    /// by colour: `surface-quiet` is the design system's "this has weight, and it is
    /// not an action" rank, a step firmer than the green wash the icon circle and the
    /// plan capsule wear, and the wordmark it carries is a mark rather than a label.
    /// The outline it used to wear did that job too, but paid for it by being the one
    /// unfilled thing in a row of fills — which reads as unfinished rather than as a
    /// class of its own (P-2).
    private var proButton: some View {
        Button(action: onPro) {
            // `verbatim` is load-bearing, not style: handing `Text` a bare string
            // literal takes the `LocalizedStringKey` path, and the next catalog sync
            // would lift the mark out as a new key across ten locales — for a label
            // that is not translated in any of them (the same reason as
            // `StreakBadge`'s digits).
            //
            // The line limit and the scale factor never fire on three Latin glyphs at
            // any text size; they are there for the second someone translates the
            // label anyway, and they are what makes that a squeeze instead of a
            // truncation.
            //
            // The wordmark, not the word: caps at 12pt / 600 with .16em of tracking
            // are what the handoff calls the premium work — the spacing does it, so
            // nothing is spent on a crown, a gradient or the accent. Caps are safe to
            // set verbatim in all ten locales for the same reason the word was, and
            // the spoken label below is what keeps a screen reader from spelling the
            // three letters out.
            Text(verbatim: "PRO")
                .font(.hanken(12, .semibold))
                // Plain `tracking`, not `overlineTracking`: that modifier drops the
                // spacing in Arabic and Korean because it exists for text those
                // locales actually set in their own script, and this is three Latin
                // glyphs everywhere. The badge in the plan editor reaches for the flat
                // modifier for the same reason, though at a quarter of this value —
                // it is a badge inside a row of text, not a mark. The tracking trails
                // the last glyph exactly as the letter spacing does in the handoff's
                // own render, so the two agree.
                .tracking(12 * 0.16)
                // `ink` on a light fill, and that is the whole contrast fix. Measured
                // on the running build the outlined label sat at 2.76:1 against the
                // backdrop — under the 3:1 a control owes, and paler than the caption
                // beside it: the door you pay through, drawn in the colour of a
                // footnote. On `surfaceQuiet` the mark reads at 12.2:1 light and
                // 13.7:1 dark — clear of the threshold rather than balanced on it, and
                // above the ~9 the handoff predicted. No new shade enters the header
                // either: the fill is a system rank, drawn for the reversible-action
                // surfaces of the consequence sheets as much as for this control,
                // which is why it lives in the theme. Today this is its only caller.
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                // A real capsule of the row's own height, and the *pinning* is as much
                // of the fix as the fill. The label used to scale with the text size
                // while both neighbours — the 34pt info circle and the 34pt streak
                // pill — did not, so at the xxLarge ceiling the padding grew the
                // outline to 44×37 (measured) against a 34×34 circle: the emptiest
                // control in the row also the largest, which reads as a placeholder.
                // Below the ceiling it was 39.5×33, a capsule with 6.5pt of straight
                // run between its two end caps — the pinched lozenge the wiki calls
                // out, neither circle nor pill.
                //
                // The width is not the wash the handoff expected, and its arithmetic
                // does not survive contact with this file: it buys the mark back by
                // dropping a 1pt border and taking the side padding 13 → 11, but the
                // padding here was 10, and the border was an `.overlay`, which costs
                // no layout width at all. Nothing was returned and 2pt were spent.
                // Measured on the 375pt frame the control goes 39.5 → 49pt at the
                // default text size and 44 → 54.5pt at the xxLarge ceiling.
                //
                // Affordable anyway, and measured rather than assumed — the row has
                // been on its edge since IF-18. In the tightest state that can be
                // reached (French, the largest type, a two-digit streak beside a 14:10
                // plan) the row lands on the same rung of the ladder as before, with
                // 55.5pt of slack left between the plan capsule and the cluster, down
                // from 64.5. Nothing gave way that had not given way already.
                //
                // The height is clamped, not merely floored, which is safe while
                // `AppFlowView` caps dynamic type at xxLarge: the mark's line box is
                // well inside 34 there. Raising that ceiling is what would need this
                // looked at again.
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(Capsule().fill(theme.surfaceQuiet))
                // The fill stays its own height and the target becomes 44. The shape
                // is a rectangle, not the capsule it is drawn as, and unlike the
                // streak badge — that one is wide enough that a capsule target costs
                // nothing, while this one is barely wider than it is tall, so capsule
                // corners would eat most of what the 44 was for. Its neighbour below
                // does the same, and the 8pt row spacing keeps the two rectangles
                // apart.
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("timer.pro")
        // "Pro" read aloud on its own tells a blind user nothing, so the label is the
        // product's whole name; the hint is the one every gated control already
        // shares, and this is its third consumer.
        .accessibilityLabel(strings.Pro.productName)
        .accessibilityHint(strings.Pro.lockedDestinationHint)
    }

    /// One candidate row for the pill. `fixedSize` is what makes the choice honest:
    /// without it a candidate reports the width it could squeeze down to, and the
    /// wider one always "fits" — by breaking words.
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
            // The last thing the pill has to give before the row starts costing
            // controls. It is the hint that the ratio is editable, not the way in:
            // the whole capsule is the button either way, and an unlabelled SF
            // symbol adds nothing to the spoken label, so dropping it costs a
            // sighted user a cue and a VoiceOver user nothing. On the one row that
            // cannot afford it the glyph goes and the control stays.
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
