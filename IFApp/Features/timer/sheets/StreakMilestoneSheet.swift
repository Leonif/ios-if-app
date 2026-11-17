//
//  StreakMilestoneSheet.swift
//  IFApp
//

import SwiftUI

struct StreakMilestoneSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOpen: Bool
    let days: Int
    let theme: ThemeTokens
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
            flameMark
            Text(strings.Streak.milestoneTitle(days))
                .font(.bricolage(23))
                .foregroundColor(theme.ink)
                .accessibilityIdentifier("streak.milestone.title")
            Text(strings.Streak.milestoneSubtitle)
                .font(.hanken(14, .medium))
                .foregroundColor(theme.mut)
                .multilineTextAlignment(.center)
            PrimaryButton(title: strings.Streak.milestoneClose, theme: theme, action: onDismiss)
                .padding(.top, 6)
                .accessibilityIdentifier("streak.milestone.close")
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, max(22, 40 - bottomInset))
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ContentLayout.sheetCornerRadius, style: .continuous)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
        .frame(maxWidth: ContentLayout.maxWidth)
    }

    private var flameMark: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundColor(theme.accent)
            .frame(width: 46, height: 46)
            .background(
                Circle().fill(theme.iconCircle)
            )
    }
}
