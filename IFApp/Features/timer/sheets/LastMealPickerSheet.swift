//
//  LastMealPickerSheet.swift
//  IFApp
//
//  The key flow: back-date a fast. Two thirds of everyone who starts a fast comes
//  through here.
//
//  The question the user is answering is "how long ago", so that is the control:
//  one ribbon covering the whole domain, four presets for the common answers, and
//  the clock time demoted to a caption that follows from the choice. There is no
//  date control any more — the day is a consequence, not an input.
//
//  The readout sits *above* the ribbon on purpose: a finger on the ribbon covers
//  the bottom third of the sheet, and that is precisely when the value matters.
//

import SwiftUI

struct LastMealPickerSheet: View {
    let minutesAgo: Int
    /// Minute-of-day of "now", injected by the flow — the ribbon's midnight rules
    /// need it, and the reducer must never read a clock itself.
    let nowMinuteOfDay: Int
    let readout: String              // "2h 40m ago"
    let absoluteLabel: String        // "Yesterday at 8:00 PM"
    /// Set only when the sheet was opened from the closed eating window, where the
    /// value was put there by the app rather than chosen by the user.
    let overline: String?
    let selectedChip: Int            // -1 = none
    let theme: ThemeTokens
    let onChip: (MealChip) -> Void
    let onScrub: (Int) -> Void
    let onFeedback: (MealScrubFeedback) -> Void
    let onExactTime: (Date) -> Void
    let onConfirm: () -> Void
    let onClose: () -> Void

    @State private var showExactPicker = false
    @State private var exactDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var atLimit: Bool { minutesAgo >= MealScale.maxMinutes }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.22)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
        }
        // The card sits 20pt off the physical bottom edge, as drawn: the Confirm
        // button still clears the home indicator by 30pt, and honouring the safe area
        // on top of that would push the sheet a third of the way up the screen.
        .ignoresSafeArea(.container, edges: .bottom)
        .transition(.opacity)
        .sheet(isPresented: $showExactPicker) { exactTimeSheet }
    }

    private var card: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.surfaceLine)
                .frame(width: 38, height: 4)
                .padding(.bottom, 15)

            VStack(alignment: .leading, spacing: 4) {
                Text(strings.Sheet.whenDidYouEat)
                    .font(.bricolage(20))
                    .foregroundColor(theme.ink)
                Text(strings.Sheet.backdateHint)
                    .font(.hanken(13, .medium))
                    // line-height 1.45 from the handoff. SwiftUI's own line box is
                    // tighter than a CSS one, so the leading is added back explicitly —
                    // between lines (German wraps to two) and under the last one.
                    .lineSpacing(13 * 1.45 - 15.6)
                    .padding(.bottom, 3)
                    .foregroundColor(theme.mut)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            chips
                .padding(.top, 14)

            readoutBlock
                .padding(.top, 18)

            MealScaleRibbon(
                minutesAgo: minutesAgo,
                nowMinuteOfDay: nowMinuteOfDay,
                theme: theme,
                a11yLabel: strings.Meal.scaleA11yLabel,
                a11yValue: "\(readout), \(absoluteLabel)",
                onScrub: onScrub,
                onFeedback: onFeedback
            )
            .padding(.top, 19)

            if atLimit {
                Text(strings.Meal.scaleLimitNote)
                    .font(.hanken(12.5, .semibold))
                    .foregroundColor(theme.mut)
                    .multilineTextAlignment(.center)
                    .padding(.top, 9)
                    .accessibilityIdentifier("meal.limitNote")
            }

            // A 13pt collar around the label lifts a one-line text link to a 44pt tap
            // target, and that target is part of the layout — the handoff measures the
            // 12pt above and the 6pt below to the edges of the 44pt box, not to the
            // text.
            Button {
                exactDate = Date().addingTimeInterval(-Double(minutesAgo) * 60)
                showExactPicker = true
            } label: {
                Text(strings.Meal.setExactTime)
                    .font(.hanken(13.5, .semibold))
                    .foregroundColor(theme.deep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .padding(.top, 9)

            PrimaryButton(title: strings.Sheet.confirm, theme: theme,
                          cornerRadius: 16, height: 54, action: onConfirm)
                .padding(.top, 6)
                .accessibilityIdentifier("meal.confirm")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(theme.sheetBg)
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(theme.surfaceLine, lineWidth: 1))
                .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
        )
    }

    // MARK: Chips

    private var chips: some View {
        // Not an equal four-way split: "Last night" is one word in English and three
        // in Polish, and equal shares would crop it. The row wraps instead.
        ChipFlowLayout(spacing: 8) {
            ForEach(MealChip.allCases, id: \.rawValue) { chip in
                let isSelected = chip.rawValue == selectedChip
                Button { onChip(chip) } label: {
                    Text(title(for: chip))
                        .font(.hanken(14.5, isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? theme.deep : theme.sec)
                        .lineLimit(1)
                        .padding(.horizontal, 15)
                        .frame(minHeight: 44)
                        .background(
                            Capsule()
                                .fill(isSelected ? theme.chipSelectedBg : theme.secBg)
                                // strokeBorder, not stroke: a 1.5pt selected border
                                // drawn on the centre line would make the selected chip
                                // 1.5pt taller than its neighbours.
                                .overlay(
                                    Capsule().strokeBorder(
                                        isSelected ? theme.chipSelectedBorder : theme.secLine,
                                        lineWidth: isSelected ? 1.5 : 1
                                    )
                                )
                        )
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier(identifier(for: chip))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func identifier(for chip: MealChip) -> String {
        switch chip {
        case .justNow: return "meal.chip.justNow"
        case .oneHour: return "meal.chip.oneHour"
        case .threeHours: return "meal.chip.threeHours"
        case .lastNight: return "meal.chip.lastNight"
        }
    }

    private func title(for chip: MealChip) -> String {
        switch chip {
        case .justNow: return strings.Meal.justNow
        case .oneHour: return strings.Meal.chip1h
        case .threeHours: return strings.Meal.chip3h
        case .lastNight: return strings.Meal.chipLastNight
        }
    }

    // MARK: Readout

    private var readoutBlock: some View {
        VStack(spacing: 0) {
            if let overline {
                Text(overline)
                    .font(.hanken(11, .semibold))
                    .textCase(.uppercase)
                    .overlineTracking(1.54)
                    .foregroundColor(theme.mut)
                    .padding(.bottom, 6)
            }
            Text(readout)
                .font(.bricolage(34))
                .monospacedDigit()
                // The system's own numeric roll: each digit that actually changed
                // slides, the rest hold still. Duration is kept under the ribbon's
                // 45ms haptic throttle, so a fast scrub still lands on the value
                // instead of queueing a backlog of animations.
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.12), value: readout)
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(absoluteLabel)
                .font(.hanken(14.5, .semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.12), value: absoluteLabel)
                .foregroundColor(theme.sec)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                // 5pt in the handoff is a CSS margin between line boxes; Bricolage's
                // descender space already accounts for most of it here.
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        // Read as one sentence; two separate elements would make VoiceOver announce
        // the duration and the clock time as unrelated facts.
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("meal.readout")
    }

    // MARK: Exact time

    private var exactTimeSheet: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: $exactDate,
                in: Date().addingTimeInterval(-Double(MealScale.maxMinutes) * 60)...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .frame(maxHeight: .infinity, alignment: .center)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(strings.Sheet.done) {
                        onExactTime(exactDate)
                        showExactPicker = false
                    }
                }
            }
        }
        .presentationDetents([.height(340)])
    }
}

/// A wrapping row: each chip takes the width of its own label and the row breaks
/// when the next one no longer fits.
private struct ChipFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth > 0 && rowWidth + spacing + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var used: CGFloat = 0
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if used > 0 && used + size.width > bounds.width {
                used = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            // No manual mirroring: SwiftUI already resolves a Layout's placement
            // against the layout direction, so an Arabic row fills from the right on
            // its own.
            view.place(at: CGPoint(x: bounds.minX + used, y: y), proposal: ProposedViewSize(size))
            used += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
