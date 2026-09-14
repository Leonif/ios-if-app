//
//  EndEatingConfirmSheet.swift
//  IFApp
//
//  Confirmation in front of ending an open eating window early. Built as a bottom
//  sheet for the same reason as ResetConfirmSheet: on iOS 26 the system
//  `.confirmationDialog` renders as a popover that hides the `.cancel` button.
//
//  Why it exists at all: the footer button ended the window on the tap, and it sits
//  full width directly under "Start fast", where a label like "Done" read as "close
//  this screen". Ending the window also drops its closing push, so a mis-tap cost the
//  one reminder the window was there to deliver.
//

import SwiftUI

struct EndEatingConfirmSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOpen: Bool
    let theme: ThemeTokens
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    // Same structure as ResetConfirmSheet: the stack always exists and only its
    // children come and go, each on its own transition.
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
            Text(strings.EndEating.confirmTitle)
                .font(.bricolage(23))
                .foregroundColor(theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(strings.EndEating.confirmMessage)
                .font(.hanken(14, .medium))
                .foregroundColor(theme.mut)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onConfirm) {
                Text(strings.EndEating.confirmAction)
                    .font(.hanken(17, .bold))
                    .foregroundColor(.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.pressable)
            .padding(.top, 6)
            .accessibilityIdentifier("endEating.confirm")

            // Last on purpose: the finger that just tapped the footer button sits low
            // on the screen, and a second tap from it has to land on the safe action.
            PrimaryButton(title: strings.EndEating.keepOpen, theme: theme, action: onDismiss)
                .accessibilityIdentifier("endEating.keepOpen")
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
