//
//  DeleteFastSheet.swift
//  IFApp
//
//  Delete confirmation for a history record. Built as a bottom sheet for the same
//  reason as ResetConfirmSheet: on iOS 26 the system `.confirmationDialog` renders
//  as a popover that hides the `.cancel` button, leaving only the destructive
//  action on screen — the opposite of what a confirmation is for.
//

import SwiftUI

struct DeleteFastSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOpen: Bool
    let theme: ThemeTokens
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if isOpen {
                    Color.black.opacity(theme.isDark ? 0.5 : 0.35)
                        .ignoresSafeArea()
                        .onTapGesture(perform: onDismiss)
                        .transition(.opacity)
                }
                if isOpen {
                    sheet(bottomInset: proxy.safeAreaInsets.bottom)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(isOpen)
        }
    }

    private func sheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: 14) {
            Text(strings.History.deleteTitle)
                .font(.bricolage(23))
                .foregroundColor(theme.ink)
            Text(strings.History.deleteBody)
                .font(.hanken(14, .medium))
                .foregroundColor(theme.mut)
                .multilineTextAlignment(.center)

            // Destructive, so it does not borrow the app's green primary button.
            Button(action: onConfirm) {
                Text(strings.History.delete)
                    .font(.hanken(17, .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.red))
            }
            .buttonStyle(.pressable)
            .padding(.top, 6)
            .accessibilityIdentifier("history.delete.confirm")

            SecondaryButton(title: strings.History.cancel, theme: theme, action: onDismiss)
                .accessibilityIdentifier("history.delete.cancel")
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, max(22, 40 - bottomInset))
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
