//
//  PlanEditorSheet.swift
//  IFApp
//

import SwiftUI

struct PlanEditorSheet: View {
    let plan: Plan
    let isPro: Bool
    let theme: ThemeTokens
    let onSelect: (Int) -> Void
    let onDone: (Int) -> Void
    let onClose: () -> Void
    let onSunnah: () -> Void

    @State private var pickerOpen = false

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

    private var shown: Plan { draftHours.map(Plan.init(hours:)) ?? plan }

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

            Button(action: onSunnah) {
                HStack {
                    Text(SunnahStrings.title).font(.hanken(15, .medium))
                    Spacer(minLength: 10)
                    Image(systemName: "chevron.forward")
                }
                .foregroundStyle(theme.deep)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plan.sunnah")
            .padding(.bottom, 12)

            SegmentedControl(
                options: Plan.presets.map(\.ratioLabel),
                selectedIndex: Plan.presets.firstIndex(of: shown) ?? -1,
                theme: theme,
                onSelect: {
                    pickerOpen = false
                    draftHours = nil
                    onSelect(Plan.presets[$0].hours)
                }
            )
            .opacity(pickerOpen ? 0.75 : 1)

            valueLine
                .padding(.top, 18)
                .padding(.bottom, 20)

            customRow

            PrimaryButton(title: strings.PlanEditor.confirm, theme: theme) { onDone(shown.hours) }
                .padding(.top, 20)
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

    // MARK: - Custom

    private var customRow: some View {
        VStack(spacing: 0) {
            Button {
                pickerOpen.toggle()
            } label: {
                LabeledActionRow(title: strings.Sheet.customLength,
                                 caption: strings.Sheet.customCaption,
                                 theme: theme, isEmphasized: pickerOpen) {
                    trailing
                }
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

    @ViewBuilder
    private var trailing: some View {
        if !isPro {
            HStack(spacing: 6) {
                Image("pro-lock")
                    .renderingMode(.template)
                Text(verbatim: "PRO")
                    .font(.hanken(12, .semibold))
                    .tracking(12 * 0.04)
                    .accessibilityLabel(strings.Pro.productName)
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
            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.mut)
        }
    }

    private var hourPicker: some View {
        VStack(spacing: 0) {
            Picker(String(), selection: Binding(get: { shown.hours }, set: { draftHours = $0 })) {
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
