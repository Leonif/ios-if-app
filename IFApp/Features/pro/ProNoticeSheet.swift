//
//  ProNoticeSheet.swift
//  IFApp
//

import SwiftUI

struct ProNoticeSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let notice: ProNotice?
    let theme: ThemeTokens
    let onDismiss: () -> Void

    private var isOpen: Bool { notice != nil }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if isOpen {
                    Color.black.opacity(theme.isDark ? 0.5 : 0.35)
                        .ignoresSafeArea()
                        .onTapGesture(perform: onDismiss)
                        .transition(.opacity)
                }
                if let notice {
                    sheet(notice, bottomInset: proxy.safeAreaInsets.bottom)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(isOpen)
        }
    }

    private func sheet(_ notice: ProNotice, bottomInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title(notice))
                .font(.hanken(17, .semibold))
                .foregroundColor(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(body(notice))
                .font(.hanken(15))
                .lineSpacing(15 * 0.3)
                .foregroundColor(theme.sec)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: strings.Pro.close, theme: theme, action: onDismiss)
                .padding(.top, 10)
                .accessibilityIdentifier("proNotice.close")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, max(22, 40 - bottomInset))
        .background(
            RoundedRectangle(cornerRadius: ContentLayout.sheetCornerRadius, style: .continuous)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
        .frame(maxWidth: ContentLayout.maxWidth)
        .accessibilityIdentifier("proNotice")
    }

    private func title(_ notice: ProNotice) -> String {
        switch notice {
        case .entitlementRevoked: return strings.Pro.revokedTitle
        case .goalChanged: return strings.Pro.goalChangedTitle
        }
    }

    private func body(_ notice: ProNotice) -> String {
        switch notice {
        case .entitlementRevoked: return strings.Pro.revokedBody
        case let .goalChanged(hours): return strings.Pro.goalChangedBody(strings.Duration.hoursSpelled(hours))
        }
    }
}
