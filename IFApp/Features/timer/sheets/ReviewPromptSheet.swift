//
//  ReviewPromptSheet.swift
//  IFApp
//
//  "Enjoying IF24?" rating pre-prompt (bottom sheet). Shown after a qualifying
//  completed fast; the positive tap opens the App Store write-review form.
//  Filters happy users before any App Store review request.
//

import SwiftUI

struct ReviewPromptSheet: View {
    let theme: ThemeTokens
    let onPositive: () -> Void
    let onDismiss: () -> Void

    private let gold = Color(hex: "#E7C36A")

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(theme.isDark ? 0.5 : 0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            sheet
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var sheet: some View {
        VStack(spacing: 14) {
            ringMark
            starRow
                .padding(.top, 2)
            Text(strings.Review.title)
                .font(.bricolage(23))
                .foregroundColor(theme.ink)
            Text(strings.Review.subtitle)
                .font(.hanken(14, .medium))
                .foregroundColor(theme.mut)
                .multilineTextAlignment(.center)
            PrimaryButton(title: strings.Review.positive, theme: theme, action: onPositive)
                .padding(.top, 6)
                .accessibilityIdentifier("review.positive")
            Button(action: onDismiss) {
                Text(strings.Review.dismiss)
                    .font(.hanken(15, .semibold))
                    .foregroundColor(theme.mut)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
            }
            .accessibilityIdentifier("review.dismiss")
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var ringMark: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(
                AngularGradient(colors: [gold, theme.accent, theme.deep], center: .center),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: 46, height: 46)
    }

    private var starRow: some View {
        HStack(spacing: 7) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(gold)
            }
        }
    }
}
