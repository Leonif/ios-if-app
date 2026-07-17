//
//  ResetConfirmSheet.swift
//  IFApp
//
//  Reset confirmation (bottom sheet). Replaces the system `.confirmationDialog`,
//  which on iOS 26 renders as a popover that hides the `.cancel` button, leaving
//  only the destructive action visible. Two explicit actions instead: confirm the
//  reset, or keep fasting.
//

import SwiftUI

struct ResetConfirmSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOpen: Bool
    let theme: ThemeTokens
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    // The stack itself always exists and only its children come and go: inserting
    // the stack would hand SwiftUI's default opacity transition to everything
    // inside, and the fade would swallow the sheet's travel. Separate `if`s so the
    // scrim and the sheet are inserted independently, each on its own transition.
    var body: some View {
        // Read the real bottom inset so the card lifts off the edge consistently:
        // on home-indicator devices the inset provides the gap, on home-button ones
        // (inset 0) a fixed minimum stands in so the dismiss button isn't jammed.
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if isOpen {
                    Color.black.opacity(theme.isDark ? 0.5 : 0.35)
                        .ignoresSafeArea()
                        .onTapGesture(perform: onDismiss)
                        .transition(.opacity)
                }
                if isOpen {
                    // Full opacity the whole way up — it should read as a solid thing
                    // that was always waiting below the edge, not one materialising
                    // mid-flight.
                    sheet(bottomInset: proxy.safeAreaInsets.bottom)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The GeometryReader fills the overlay even when closed; keep it from
            // swallowing taps meant for the timer behind it until it's actually open.
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
            PrimaryButton(title: strings.Reset.confirmAction, theme: theme, action: onConfirm)
                .padding(.top, 6)
                .accessibilityIdentifier("reset.confirm")
            SecondaryButton(title: strings.Reset.keepFasting, theme: theme, action: onDismiss)
                .accessibilityIdentifier("reset.cancel")
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        // Card content respects the safe area, so `bottomInset` already lifts it;
        // this keeps the total gap at ~40pt when the inset is small (home button).
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
