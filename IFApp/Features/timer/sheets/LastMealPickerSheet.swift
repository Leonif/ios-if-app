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
                .tracking(1.3)
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
            HStack(spacing: 10) {
                circleButton("chevron.left", action: onMinus)
                Text(value)
                    .font(.hanken(15, .bold))
                    .foregroundColor(theme.ink)
                    .frame(minWidth: 108)
                    .multilineTextAlignment(.center)
                circleButton("chevron.right", action: onPlus)
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

    private var preview: some View {
        let c = theme.chip(for: theme.deep)
        return HStack {
            Text(strings.Sheet.fastingSince)
                .font(.hanken(13, .semibold))
                .foregroundColor(theme.sec)
            Spacer()
            Text(previewText)
                .font(.hanken(13.5, .bold))
                .foregroundColor(theme.deep)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(c.bg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(c.border, lineWidth: 1))
        )
    }
}
