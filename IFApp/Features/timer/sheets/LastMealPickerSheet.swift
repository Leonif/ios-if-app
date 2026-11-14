//
//  LastMealPickerSheet.swift
//  IFApp
//

import SwiftUI

struct LastMealPickerSheet: View {
    let minutesAgo: Int
    let nowMinuteOfDay: Int
    let readout: String
    let absoluteLabel: String
    let overline: String?
    let selectedChip: Int
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

    private let sectionGap: CGFloat = 16
    private let tightGap: CGFloat = 8

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.22)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .transition(.opacity)
        .sheet(isPresented: $showExactPicker) { exactTimeSheet }
    }

    private var card: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.surfaceLine)
                .frame(width: 38, height: 4)
                .padding(.bottom, sectionGap)

            Text(strings.Sheet.whenDidYouEat)
                .font(.bricolage(20))
                .foregroundColor(theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            chips
                .padding(.top, sectionGap)

            readoutBlock
                .padding(.top, sectionGap)

            MealScaleRibbon(
                minutesAgo: minutesAgo,
                nowMinuteOfDay: nowMinuteOfDay,
                theme: theme,
                a11yLabel: strings.Meal.scaleA11yLabel,
                a11yValue: strings.Meal.scaleA11yValue(readout, absoluteLabel),
                onScrub: onScrub,
                onFeedback: onFeedback
            )
            .padding(.top, sectionGap)

            if atLimit {
                Text(strings.Meal.scaleLimitNote)
                    .font(.hanken(12.5, .semibold))
                    .foregroundColor(theme.mut)
                    .multilineTextAlignment(.center)
                    .padding(.top, tightGap)
                    .accessibilityIdentifier("meal.limitNote")
            }

            Button {
                exactDate = Date().addingTimeInterval(-Double(minutesAgo) * 60)
                showExactPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .semibold))
                    Text(strings.Meal.setExactTime)
                        .font(.hanken(14, .semibold))
                }
                .foregroundColor(theme.deep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(theme.secBg)
                        .overlay(Capsule().strokeBorder(theme.secLine, lineWidth: 1))
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.pressable)
            .padding(.top, tightGap)

            PrimaryButton(title: strings.Sheet.confirm, theme: theme,
                          cornerRadius: 16, height: 54, action: onConfirm)
                .padding(.top, tightGap)
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

    // MARK: - Chips

    private var chips: some View {
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

    // MARK: - Readout

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
            Text(absoluteLabel)
                .font(.bricolage(34))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.12), value: absoluteLabel)
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(readout)
                .font(.hanken(14.5, .semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.12), value: readout)
                .foregroundColor(theme.sec)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("meal.readout")
    }

    // MARK: - Exact time

    private var exactTimeSheet: some View {
        NavigationStack {
            DatePicker(
                String(),
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
                    Button(strings.Meal.exactTimeDone) {
                        onExactTime(exactDate)
                        showExactPicker = false
                    }
                }
            }
        }
        .presentationDetents([.height(340)])
    }
}

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
            view.place(at: CGPoint(x: bounds.minX + used, y: y), proposal: ProposedViewSize(size))
            used += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
