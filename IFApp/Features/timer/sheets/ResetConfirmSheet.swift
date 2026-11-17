//
//  ResetConfirmSheet.swift
//  IFApp
//

import SwiftUI

struct ResetConfirmSheet: View {
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
            Text(strings.Reset.confirmTitle)
                .font(.bricolage(23))
                .foregroundColor(theme.ink)
            Text(strings.Reset.confirmMessage)
                .font(.hanken(14, .medium))
                .foregroundColor(theme.mut)
                .multilineTextAlignment(.center)
            Button(action: onConfirm) {
                Text(strings.Reset.confirmAction)
                    .font(.hanken(17, .bold))
                    .foregroundColor(.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.pressable)
            .padding(.top, 6)
            .accessibilityIdentifier("reset.confirm")

            PrimaryButton(title: strings.Reset.keepThisFast, theme: theme, action: onDismiss)
                .accessibilityIdentifier("reset.cancel")
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, max(22, 40 - bottomInset))
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: -6)
                .ignoresSafeArea(edges: [.horizontal, .bottom])
        )
    }
}
