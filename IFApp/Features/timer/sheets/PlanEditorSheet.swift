//
//  PlanEditorSheet.swift
//  IFApp
//
//  Top-anchored overlay card with a dimmed backdrop (tap-out to close).
//
//  Rebuilt in 1.5.0. The white row that printed "Eating window · 12:00 - 8:00 PM" is
//  gone: those hours were invented, this app runs on anchors, and the card was also
//  a card-shaped thing that looked tappable and was not. Duration is the only true
//  value and it is stated once, in the value line. What replaces it is a row that
//  does respond — Custom, its own row under the control rather than a fifth segment,
//  because a segmented control promises immediate choice and a segment that opens a
//  sales screen instead breaks that promise half a centimetre under "Tap to change".
//
//  For someone without Pro the picker still opens and still turns. Only confirming is
//  locked, and confirming is what opens the offer: a decision to buy should not have
//  to be made from a description.
//

import SwiftUI

struct PlanEditorSheet: View {
    let plan: Plan
    /// Whether a custom length can be confirmed. The picker ignores this — it turns
    /// either way.
    let isPro: Bool
    let theme: ThemeTokens
    /// Reports the chosen plan by its length in hours, not by segment position: the
    /// segments are the four presets, and a plan is no longer a place in that list.
    let onSelect: (Int) -> Void
    /// Confirming, with the length the sheet is showing. It travels as an argument
    /// rather than being read back off the store, because until the gate lets it
    /// through it is not in the store.
    let onDone: (Int) -> Void
    let onClose: () -> Void

    @State private var pickerOpen = false

    /// What the wheel is showing, or `nil` for "whatever the store says".
    ///
    /// The wheel turns a draft and not the plan itself. Dispatching on every detent
    /// wrote a length into the store before anything had checked the entitlement, so
    /// a free user who span up to 17, met the offer and walked away was left with a
    /// plan the app would not fast to — visible in the header, persisted across a
    /// cold start, and reported to GA4 as a confirmed custom plan.
    @State private var draftHours: Int?

    var body: some View {
        ZStack(alignment: .top) {
            Color(.sRGB, red: 24/255, green: 20/255, blue: 14/255, opacity: 0.22)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 18)
                .padding(.top, 70)
        }
        .transition(.opacity)
    }

    /// The plan on screen: the draft while the wheel owns the value, the store's plan
    /// otherwise. Every part of the card that states the plan reads this one value, so
    /// the value line, the trailing number and the lit segment cannot disagree.
    private var shown: Plan { draftHours.map(Plan.init(hours:)) ?? plan }

    /// Whether `Done` applies the plan or opens the offer. Asked about what is on
    /// screen, at the moment of confirming.
    private var canConfirm: Bool { shown.allowed(isPro: isPro) }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(strings.Sheet.fastingPlan)
                .font(.bricolage(22, .semibold))
                .displayTracking(22, -0.01)
                .foregroundColor(theme.ink)
                .padding(.bottom, 6)

            Text(strings.Sheet.planSubtitle)
                .font(.hanken(15))
                .lineSpacing(15 * 0.3)
                .foregroundColor(theme.sec)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)

            SegmentedControl(
                options: Plan.presets.map(\.ratioLabel),
                // A custom plan matches no segment, and none is highlighted: leaving
                // 16:8 lit next to a 17 h value would be a stale answer, not a quiet
                // one.
                selectedIndex: Plan.presets.firstIndex(of: shown) ?? -1,
                theme: theme,
                onSelect: {
                    pickerOpen = false
                    // The draft steps aside so the store's answer is the shown one
                    // again; the dispatch below is unchanged, and this is still the
                    // one path that writes a plan straight through.
                    draftHours = nil
                    onSelect(Plan.presets[$0].hours)
                }
            )
            // The control goes quiet while the picker owns the value.
            .opacity(pickerOpen ? 0.75 : 1)

            valueLine
                .padding(.top, 18)
                .padding(.bottom, 20)

            customRow

            PrimaryButton(title: strings.PlanEditor.confirm, theme: theme) { onDone(shown.hours) }
                .padding(.top, 20)
                // On this one branch the tap opens the offer instead of applying the
                // plan, and the label cannot say so without lying on every other
                // branch. The PRO badge on the custom row above is the part that
                // survives hints being switched off; this only names the destination.
                .accessibilityHint(canConfirm ? "" : strings.Pro.lockedDestinationHint)
                .accessibilityIdentifier("plan.done")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
        )
    }

    /// "16h  fast · 8h window" — two durations and no wall clock. The number is
    /// display type and the rest is body, so they are two views, never one string.
    private var valueLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(strings.Duration.goalHours(shown.hours))
                .font(.bricolage(30, .semibold))
                .monospacedDigit()
                .displayTracking(30, -0.01)
                .foregroundColor(theme.ink)
            Text(strings.Duration.planWindowSuffix(strings.Duration.goalHours(shown.windowHours)))
                .font(.hanken(15))
                .foregroundColor(theme.sec)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Custom

    private var customRow: some View {
        VStack(spacing: 0) {
            Button {
                pickerOpen.toggle()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.Sheet.customLength)
                            .font(.hanken(16, pickerOpen ? .semibold : .medium))
                            .foregroundColor(pickerOpen ? theme.deep : theme.ink)
                        Text(strings.Sheet.customCaption)
                            .font(.hanken(13))
                            .lineSpacing(13 * 0.2)
                            .foregroundColor(theme.mut)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 12)
                    trailing
                }
                .frame(minHeight: 56)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plan.custom")

            if pickerOpen {
                Rectangle().fill(theme.surfaceLine).frame(height: 1).padding(.horizontal, 16)
                hourPicker
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.backgroundBase))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(pickerOpen ? theme.accent.opacity(0.4) : theme.surfaceLine, lineWidth: 1)
        )
    }

    /// The lock, the value, or a chevron — all in the same trailing box, so the row
    /// does not resize when Pro turns on.
    @ViewBuilder
    private var trailing: some View {
        if !isPro {
            HStack(spacing: 6) {
                Image("pro-lock")
                    .renderingMode(.template)
                Text(verbatim: "PRO")
                    .font(.hanken(12, .semibold))
                    .tracking(12 * 0.04)
            }
            .foregroundColor(theme.deep)
            .padding(.leading, 9)
            .padding(.trailing, 11)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(theme.accent.opacity(0.14))
                    .overlay(Capsule().stroke(theme.accent.opacity(0.34), lineWidth: 1))
            )
        } else if pickerOpen {
            Text(strings.Duration.goalHours(shown.hours))
                .font(.bricolage(17, .semibold))
                .monospacedDigit()
                .foregroundColor(theme.deep)
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.mut)
        }
    }

    private var hourPicker: some View {
        VStack(spacing: 0) {
            Picker("", selection: Binding(get: { shown.hours }, set: { draftHours = $0 })) {
                ForEach(Array(Plan.range), id: \.self) { hours in
                    Text(strings.Duration.hoursSpelled(hours)).tag(hours)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 170)
            .clipped()
        }
        .padding(.bottom, 12)
    }
}
