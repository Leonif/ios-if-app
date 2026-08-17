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
    /// A broken streak still shows the pill (as "History"); no records and no streak
    /// shows none.
    let streak: Int
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
            if hasRecords || streak > 0 {
                StreakBadge(days: streak, theme: theme, onTap: onHistory)
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
    /// An outline instead of a fill is the one thing that tells it apart from its
    /// three neighbours, all of which are filled: two identical filled capsules at
    /// either end of the row would read as a matched pair of controls of one class
    /// (P-2).
    private var proButton: some View {
        Button(action: onPro) {
            // `verbatim` is load-bearing, not style: handing `Text` a bare string
            // literal takes the `LocalizedStringKey` path, and the next catalog sync
            // would lift "Pro" out as a new key across ten locales — for a label that
            // is not translated in any of them (the same reason as `StreakBadge`'s
            // digits). The literal form is spelled out in prose rather than quoted
            // here because the acceptance check for this control is a grep for it.
            //
            // The line limit and the scale factor never fire on three Latin glyphs at
            // any text size; they are there for the second someone translates the
            // label anyway, and they are what makes that a squeeze instead of a
            // truncation.
            Text(verbatim: "Pro")
                .font(.hanken(13, .medium))
                .foregroundColor(theme.mut)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                // 10pt, not the 13 of the plan pill: the whole capsule has to stay
                // within 44.5pt at the xxLarge ceiling, which is what keeps the
                // header whole in the tightest measured frame (fr, 375pt).
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(theme.iconStroke, lineWidth: 1))
                // The outline stays its own height and the target becomes 44. The
                // shape is a rectangle, not the capsule it is drawn as, and unlike
                // the streak badge — that one is wide enough that a capsule target
                // costs nothing, while this one is barely wider than it is tall, so
                // capsule corners would eat most of what the 44 was for. Its
                // neighbour below does the same, and the 8pt row spacing keeps the
                // two rectangles apart.
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
