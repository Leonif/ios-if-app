//
//  PlanEditorSheet.swift
//  IFApp
//
//  Top-anchored overlay card with a dimmed backdrop (tap-out to close).
//

import SwiftUI

struct PlanEditorSheet: View {
    let plan: Plan
    let theme: ThemeTokens
    let onSelect: (Int) -> Void
    let onDone: () -> Void
    let onClose: () -> Void

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

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Fasting plan")
                    .font(.bricolage(19))
                    .foregroundColor(theme.ink)
                Spacer()
                Text("Tap to change")
                    .font(.hanken(12, .semibold))
                    .foregroundColor(theme.mut)
            }

            SegmentedControl(
                options: Plan.allCases.map(\.ratioLabel),
                selectedIndex: plan.rawValue,
                theme: theme,
                onSelect: onSelect
            )

            HStack {
                Text("Eating window")
                    .font(.hanken(13.5, .semibold))
                    .foregroundColor(theme.sec)
                Spacer()
                Text(plan.windowLabel)
                    .font(.hanken(13.5, .bold))
                    .foregroundColor(theme.deep)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secBg)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.secLine, lineWidth: 1))
            )

            PrimaryButton(title: "Done", theme: theme, action: onDone)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
        )
    }
}
