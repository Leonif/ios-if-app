//
//  EndFastSheet.swift
//  IFApp
//
//  The end-of-fast correction sheet — four mutually exclusive cards, one component.
//  Mode A of the consequence genre: the card is not in a ScrollView and has 583pt to
//  live in on an iPhone SE 3, so every new line REPLACES an existing one rather than
//  adding to it. The near-goal line takes the hint's slot; the refusal takes the
//  whole card.
//
//  Two rules run through all four states and neither is stylistic:
//
//  - **No fixed heights on text.** Every block is a `minHeight` with slack. A box
//    measured off the English mock-up overflows in German, and that defect does not
//    look like a clip — it looks like overlap.
//  - **No `minimumScaleFactor`.** At the xxLarge ceiling a label wider than ~153pt
//    renders below base size under a 0.7 floor: someone turned text up and got
//    smaller type. Text wraps and the block grows instead.
//

import SwiftUI

struct EndFastSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: EndFastState
    /// The clock the labels are drawn against. Passed in rather than read here: a
    /// view that reads the clock cannot be rendered twice and compared.
    let now: Double
    let theme: ThemeTokens
    let onChip: (EndFastChipOffset) -> Void
    let onStep: (Int) -> Void
    let onConfirm: () -> Void
    let onKeepFast: () -> Void
    let onPickAnotherTime: () -> Void
    let onOpenConflict: (FastRecord) -> Void
    let onClose: () -> Void

    /// The consequence message rises after the card it sits in has settled — never
    /// over a transition. Both numbers come from 1.5.0's accepted motion and are two
    /// values on purpose: the wait and the travel may be retuned apart.
    private static let messageDelay: TimeInterval = 0.42
    private static let messageRise: TimeInterval = 0.42

    @State private var messageShown = false

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
        .onAppear {
            guard !reduceMotion else { messageShown = true; return }
            // The wait is a property of the curve, not a scheduled job: `.delay` keeps
            // the pause inside the animation the view already declares, so there is no
            // timer to outlive the sheet if it closes during those 0.42s.
            withAnimation(.timingCurve(0.22, 0.8, 0.3, 1, duration: Self.messageRise)
                            .delay(Self.messageDelay)) {
                messageShown = true
            }
        }
    }

    // MARK: Card

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
        // The whole card cross-fades between states; nothing animates its layout,
        // which is why replacement is a hard rule — there is no animation available
        // to absorb a height change.
        .animation(reduceMotion ? .easeInOut(duration: 0.24) : .easeInOut(duration: 0.18),
                   value: state.stage)
    }

    // MARK: S1 / S2 / S3 — the picker

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
                // Last element, no chevron, and it repeats the noun of the line above
                // it: the pair reads as sentence and answer rather than as options
                // three and four. It is the named form of closing the sheet — the same
                // thing the scrim tap does, spelled out.
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

    /// The consequence message: the app's third register, next to prose and buttons.
    /// It is not tappable and must never look it — no press state, no chevron, and a
    /// radius small enough that it cannot be mistaken for a card.
    private func consequenceInset(_ text: String) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.hanken(14, .medium))
                .lineSpacing(14 * 0.35)
                .foregroundColor(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                // Only the message moves. The fill it sits in is drawn with the card
                // and never animates.
                .opacity(messageShown ? 1 : 0)
                .offset(y: messageShown ? 0 : 28)
                .accessibilityIdentifier("endFast.consequence")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.surfaceQuiet))
    }

    // MARK: Chips

    private var chipRow: some View {
        HStack(spacing: 8) {
            // Keyed by position, not by label: two presets can be clamped onto the
            // same moment near the edge of the reachable range, and identical labels
            // would collapse the row from three chips to two.
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
            }
        }
    }

    // MARK: Exact time (S1 / S3 only)

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

    /// True while the exact-time value still sits where the sheet put it — the moment
    /// the goal ran out. The caption says so, which is the difference between "9:10 AM
    /// yesterday" and "the time your goal was reached".
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

    // MARK: Preview

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

    // MARK: S4 — the refusal

    @ViewBuilder
    private var refusalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Its own header. Reusing "When did you eat?" over a body that is no
            // longer a picker makes the header describe something that is not there.
            Text(strings.EndFast.refusalTitle)
                .font(.bricolage(20))
                .foregroundColor(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("endFast.refusalTitle")

            // Budgeted for four German lines by minimum height, never a fixed one: a
            // fifth line grows the block instead of running under the actions.
            HStack(spacing: 0) {
                Text(strings.EndFast.refusalReason(conflictSpan))
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

            // Two live exits. Nothing here is dimmed or disabled: a silently inactive
            // control is the unsaid refusal this state exists to replace.
            VStack(spacing: 10) {
                SheetPrimaryButton(title: strings.EndFast.pickAnotherTime,
                                   theme: theme, action: onPickAnotherTime)
                    .accessibilityIdentifier("endFast.pickAnother")
                QuietActionButton(title: strings.EndFast.openThatFast, theme: theme) {
                    if let conflict = state.conflict { onOpenConflict(conflict) }
                }
                .accessibilityIdentifier("endFast.openConflict")
            }
            .padding(.top, 2)
        }
    }

    private var conflictSpan: String {
        state.conflict.map { EndFastMath.recordSpan($0, now: now) } ?? ""
    }
}
