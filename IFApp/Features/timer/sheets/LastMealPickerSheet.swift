//
//  LastMealPickerSheet.swift
//  IFApp
//
//  The key flow: back-date a fast. One container, quick chips + exact date/time
//  steppers, all reading from a single source of truth with a live preview.
//

import SwiftUI

struct LastMealPickerSheet: View {
    let dateLabel: String       // "Today" / "Yesterday" / "n days ago"
    let timeLabel: String       // "7:00 PM"
    let previewText: String     // "7:00 PM · 2h 40m in"
    let theme: ThemeTokens
    let onQuickChip: (Int) -> Void      // minutes ago: 30/60/120
    let onDayStep: (Int) -> Void        // +1 older / -1 newer
    let onTimeStep: (Int) -> Void       // ±15 minutes
    let onConfirm: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.22)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 18)
                .padding(.top, 64)
        }
        .transition(.opacity)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(strings.Sheet.whenDidYouEat)
                    .font(.bricolage(20))
                    .foregroundColor(theme.ink)
                Text(strings.Sheet.backdateHint)
                    .font(.hanken(13, .medium))
                    .foregroundColor(theme.mut)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SegmentedControl(
                options: [strings.Sheet.chip30Min, strings.Sheet.chip1Hour, strings.Sheet.chip2Hours],
                selectedIndex: -1,
                theme: theme,
                onSelect: { idx in onQuickChip([30, 60, 120][idx]) }
            )

            dividerLabel

            stepperRow(label: strings.Sheet.date,
                       value: dateLabel,
                       onMinus: { onDayStep(1) },   // ◁ older
                       onPlus: { onDayStep(-1) })    // ▷ newer
            Rectangle().fill(theme.surfaceLine).frame(height: 1)
            stepperRow(label: strings.Sheet.time,
                       value: timeLabel,
                       onMinus: { onTimeStep(-15) },
                       onPlus: { onTimeStep(15) })

            preview

            PrimaryButton(title: strings.Sheet.confirm, theme: theme, action: onConfirm)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
        )
    }

    private var dividerLabel: some View {
        HStack(spacing: 10) {
            Rectangle().fill(theme.surfaceLine).frame(height: 1)
            Text(strings.Sheet.orSetExact)
                .font(.hanken(11, .semibold))
                .overlineTracking(1.3)
                .foregroundColor(theme.faint)
                .fixedSize()
            Rectangle().fill(theme.surfaceLine).frame(height: 1)
        }
    }

    private func stepperRow(label: String, value: String,
                            onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .font(.hanken(13.5, .semibold))
                .foregroundColor(theme.sec)
            Spacer()
            // `backward`/`forward`, not `left`/`right`. The two pairs draw the same
            // glyph in English and part company in Arabic: SF Symbols treats
            // `chevron.left` as a statement about the screen, so it keeps pointing
            // left while the row around it mirrors and the decrement button travels to
            // the other end — leaving the two arrows aimed inward at the value they
            // are supposed to step away from. The semantic pair mirrors with the row,
            // so the arrows keep pointing outward and "back" keeps meaning back. Same
            // pair `StreakBadge` and `FooterCard` already use.
            HStack(spacing: 10) {
                circleButton("chevron.backward", action: onMinus)
                Text(value)
                    .font(.hanken(15, .bold))
                    .foregroundColor(theme.ink)
                    .frame(minWidth: 108)
                    .multilineTextAlignment(.center)
                circleButton("chevron.forward", action: onPlus)
            }
        }
    }

    private func circleButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.ink)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(theme.secBg)
                        .overlay(Circle().stroke(theme.secLine, lineWidth: 1))
                )
        }
        .buttonStyle(.pressable)
    }

    /// The sheet's answer to "what happens if I confirm", so what it must never do is
    /// lose part of that answer. The slot is 275pt inside on a 375pt screen, and the
    /// value is the widest string the sheet renders — ar spends 57pt no other locale
    /// does on the tail of "%d س %02d د من الصيام", which put the pair at 287pt at the
    /// xxLarge ceiling and at 361pt once the meal was a couple of days back, over the
    /// slot at the *base* text size and not only at the top of the ramp. It wrapped:
    /// the duration came apart mid-token and Confirm slid down the card.
    ///
    /// Two rungs rather than one squeezed line, because at the ceiling one line is not
    /// available in every language and pretending otherwise costs a word. de at
    /// xxLarge with the meal six days back wants ~324pt for the value alone, so a
    /// side-by-side row there can only end in an ellipsis — and the word it eats is
    /// "gefastet", the verb the sentence is about. On the second rung the value gets
    /// the whole width and reads in full.
    ///
    /// The first rung measures honestly, which is the part that is easy to get wrong:
    /// `fixedSize` on each half makes it report the width it actually wants instead of
    /// the width it could squeeze into, so `ViewThatFits` drops to the stack when the
    /// line is genuinely too narrow rather than always "fitting" and clipping after.
    /// `TimerHeader` writes the same trap down for the same reason.
    private var preview: some View {
        let c = theme.chip(for: theme.deep)
        return ViewThatFits(in: .horizontal) {
            HStack {
                previewLabel.fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 8)
                previewValue.fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: 3) {
                previewLabel
                // The floor only has to cover the gap between the longest value and
                // one full line; the row above has already given up the label's share
                // of the width, so it is a squeeze of a few percent, not a shrink.
                previewValue.minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(c.bg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(c.border, lineWidth: 1))
        )
    }

    private var previewLabel: some View {
        Text(strings.Sheet.fastingSince)
            .font(.hanken(13, .semibold))
            .foregroundColor(theme.sec)
            .lineLimit(1)
    }

    private var previewValue: some View {
        Text(previewText)
            .font(.hanken(13.5, .bold))
            .foregroundColor(theme.deep)
            .lineLimit(1)
    }
}
