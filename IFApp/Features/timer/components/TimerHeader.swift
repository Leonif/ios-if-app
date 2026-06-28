//
//  TimerHeader.swift
//  IFApp
//
//  Top row on every state: plan pill (opens plan editor) + settings circle.
//

import SwiftUI

struct TimerHeader: View {
    let plan: Plan
    let theme: ThemeTokens
    let onEditPlan: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: onEditPlan) {
                HStack(spacing: 7) {
                    Text(plan.ratioLabel)
                        .font(.hanken(15, .bold))
                        .monospacedDigit()
                        .foregroundColor(theme.ink)
                    Text("Daily fast")
                        .font(.hanken(13, .medium))
                        .foregroundColor(theme.mut)
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(theme.iconStroke)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(Capsule().fill(theme.iconCircle))
            }
            .buttonStyle(.pressable)

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(theme.iconStroke)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(theme.iconCircle))
            }
            .buttonStyle(.pressable)
        }
    }
}
