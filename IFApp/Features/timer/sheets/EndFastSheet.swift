//
//  EndFastSheet.swift
//  IFApp
//

import SwiftUI

struct EndFastSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: EndFastState
    let now: Double
    let theme: ThemeTokens
    let onChip: (EndFastChipOffset) -> Void
    let onStep: (Int) -> Void
    let onConfirm: () -> Void
    let onKeepFast: () -> Void
    let onPickAnotherTime: () -> Void
    let onOpenConflict: (FastRecord) -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.22)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 18)
                .contentWidth()
                .padding(.top, 64)
        }
        .transition(.opacity)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            if state.stage == .refusal {
                refusalCard
            } else {
                pickerCard
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.sheetBg)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.surfaceLine, lineWidth: 1))
                .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
        )
        .animation(reduceMotion ? .easeInOut(duration: 0.24) : .easeInOut(duration: 0.18),
                   value: state.stage)
    }

    // MARK: - S1 / S2 / S3 — the picker

    @ViewBuilder
    private var pickerCard: some View {
        header
        chipRow
        if state.showsStepper {
            dividerLabel
            stepper
        }
        previewRow
        VStack(spacing: 10) {
            SheetPrimaryButton(title: primaryLabel, theme: theme, action: onConfirm)
                .accessibilityIdentifier("endFast.confirm")
            if state.stage == .nearGoal {
                QuietActionButton(title: strings.Reset.keepThisFast, theme: theme, action: onKeepFast)
                    .accessibilityIdentifier("endFast.keepFast")
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        switch state.stage {
        case .nearGoal:
            VStack(alignment: .leading, spacing: 10) {
                title(strings.EndFast.nearGoalTitle)
                consequenceInset(nearGoalLine)
            }
        case .overtime:
            VStack(alignment: .leading, spacing: 10) {
                title(strings.EndFast.title)
                consequenceInset(overtimeLine)
            }
        default:
            VStack(alignment: .leading, spacing: 7) {
                title(strings.EndFast.title)
                Text(strings.EndFast.hint)
                    .font(.hanken(13))
                    .lineSpacing(13 * 0.4)
                    .foregroundColor(theme.sec)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("endFast.hint")
            }
        }
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.bricolage(20))
            .foregroundColor(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("endFast.title")
    }

    private var nearGoalLine: String {
        guard case let .nearGoal(minutesLeft) = state.entry else { return "" }
        return strings.EndFast.minutesLeft(minutesLeft)
    }

    private var overtimeLine: String {
        guard case let .overtime(secondsPastGoal) = state.entry else { return "" }
        let total = max(0, Int(secondsPastGoal))
        return strings.EndFast.timerRanPast(strings.Duration.hm(total / 3600, (total / 60) % 60))
    }

    private func consequenceInset(_ text: String) -> some View {
        ConsequenceInset(text: text, theme: theme, identifier: "endFast.consequence")
    }

    // MARK: - Chips

    private var chipRow: some View {
        HStack(spacing: 8) {
            let chips = EndFastMath.chips(stage: state.stage, now: now,
                                          selected: state.endTimestamp)
            ForEach(chips.indices, id: \.self) { index in
                let chip = chips[index]
                Button { onChip(chip.offset) } label: {
                    Text(chip.label)
                        .font(.hanken(13, .semibold))
                        .foregroundColor(theme.sec)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(theme.surfaceQuiet))
                }
                .buttonStyle(.pressable)
                .accessibilityIdentifier("endFast.chip.\(index)")
            }
        }
    }

    // MARK: - Exact time (S1 / S3 only)

    private var dividerLabel: some View {
        HStack(spacing: 10) {
            Rectangle().fill(theme.surfaceLine).frame(height: 1)
            Text(strings.Sheet.orSetExact)
                .font(.hanken(12, .semibold))
                .overlineTracking(12 * 0.16)
                .foregroundColor(theme.mut)
                .fixedSize()
            Rectangle().fill(theme.surfaceLine).frame(height: 1)
        }
        .accessibilityIdentifier("endFast.orSetExact")
    }

    private var stepper: some View {
        HStack(spacing: 10) {
            stepButton("minus", action: { onStep(-EndFastState.stepMinutes) })
            Spacer(minLength: 0)
            VStack(spacing: 1) {
                Text(EndFastMath.clock(state.endTimestamp))
                    .font(.bricolage(22))
                    .monospacedDigit()
                    .foregroundColor(theme.ink)
                    .accessibilityIdentifier("endFast.time")
                Text(EndFastMath.dayCaption(state.endTimestamp, now: now, isGoalEnd: isOnGoalEnd))
                    .font(.hanken(11, .semibold))
                    .overlineTracking(11 * 0.1)
                    .foregroundColor(theme.mut)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("endFast.day")
            }
            Spacer(minLength: 0)
            stepButton("plus", action: { onStep(EndFastState.stepMinutes) })
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.surfaceQuiet))
    }

    private var isOnGoalEnd: Bool {
        guard case .overtime = state.entry else { return false }
        return abs(state.endTimestamp - goalEnd) < 60
    }

    private var goalEnd: Double {
        guard case let .overtime(secondsPastGoal) = state.entry else { return 0 }
        return state.latest - secondsPastGoal
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.sec)
                .frame(width: 44, height: 44)
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("endFast.step.\(symbol)")
    }

    // MARK: - Preview

    private var previewRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(strings.EndFast.fastEnds)
                .font(.hanken(12, .semibold))
                .overlineTracking(12 * 0.16)
                .foregroundColor(theme.mut)
            Spacer(minLength: 0)
            Text(EndFastMath.previewValue(end: state.endTimestamp, start: state.fastStartTimestamp))
                .font(.hanken(15, .bold))
                .monospacedDigit()
                .foregroundColor(theme.ink)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("endFast.preview")
        }
    }

    private var primaryLabel: String {
        switch state.stage {
        case .nearGoal: return strings.EndFast.endNow
        case .overtime: return strings.EndFast.setTheTime
        default: return strings.Sheet.confirm
        }
    }

    // MARK: - S4 — the refusal

    @ViewBuilder
    private var refusalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.EndFast.refusalTitle)
                .font(.bricolage(20))
                .foregroundColor(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("endFast.refusalTitle")

            HStack(spacing: 0) {
                Text(state.conflictUnavoidable
                     ? strings.EndFast.refusalReasonUnavoidable(conflictSpan)
                     : strings.EndFast.refusalReason(conflictSpan))
                    .font(.hanken(14, .medium))
                    .lineSpacing(14 * 0.42)
                    .foregroundColor(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("endFast.refusalReason")
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(theme.surfaceQuiet))

            VStack(spacing: 10) {
                if state.conflictUnavoidable {
                    SheetPrimaryButton(title: strings.EndFast.openThatFast, theme: theme) {
                        if let conflict = state.conflict { onOpenConflict(conflict) }
                    }
                    .accessibilityIdentifier("endFast.openConflict")
                } else {
                    SheetPrimaryButton(title: strings.EndFast.pickAnotherTime,
                                       theme: theme, action: onPickAnotherTime)
                        .accessibilityIdentifier("endFast.pickAnother")
                    QuietActionButton(title: strings.EndFast.openThatFast, theme: theme) {
                        if let conflict = state.conflict { onOpenConflict(conflict) }
                    }
                    .accessibilityIdentifier("endFast.openConflict")
                }
            }
            .padding(.top, 2)
        }
    }

    private var conflictSpan: String {
        state.conflict.map { EndFastMath.recordSpan($0, now: now) } ?? ""
    }
}
