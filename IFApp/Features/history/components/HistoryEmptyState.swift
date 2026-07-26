//
//  HistoryEmptyState.swift
//  IFApp
//
//  Nothing recorded yet. Ghost rings rather than an icon — the ring is the app's
//  one shape, and an empty one says "this is waiting to be filled" without a single
//  zero on screen. The copy promises what will be kept; it never scolds.
//

import SwiftUI

struct HistoryEmptyState: View {
    let theme: ThemeTokens
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ring(148)
                ring(104)
                ring(62)
                Circle()
                    .fill(theme.accent)
                    .frame(width: 8, height: 8)
                    .offset(y: -74)
            }
            .frame(width: 148, height: 148)
            .accessibilityHidden(true)

            Text(strings.History.emptyTitle)
                .font(.bricolage(25))
                .foregroundColor(theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 34)

            Text(strings.History.emptyBody)
                .font(.hanken(15.5))
                .lineSpacing(15.5 * 0.55)
                .foregroundColor(theme.sec)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 294)
                .padding(.top, 12)

            // Hugs its label rather than spanning the screen like the footer's
            // primary button — an invitation, not the screen's main action.
            Button(action: onStart) {
                Text(strings.History.emptyCta)
                    .font(.hanken(15, .bold))
                    .foregroundColor(theme.primaryButtonText)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .background(RoundedRectangle(cornerRadius: 15).fill(theme.primaryButtonBg))
                    .shadow(color: theme.buttonShadow, radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.pressable)
            .padding(.top, 26)
            .accessibilityIdentifier("history.startFast")
        }
        .frame(maxWidth: .infinity)
    }

    private func ring(_ diameter: CGFloat) -> some View {
        Circle()
            .stroke(theme.historyGhostLine, lineWidth: 1)
            .frame(width: diameter, height: diameter)
    }
}
