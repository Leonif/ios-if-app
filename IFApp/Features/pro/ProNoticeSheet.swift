//
//  ProNoticeSheet.swift
//  IFApp
//
//  One sheet, two things to say after the entitlement goes away: that it is gone
//  (edge 6) and that the next fast runs to a different goal (edge 17). They share a
//  component and never share a frame — the second arrives at the next start, which
//  can be days after the first.
//
//  Why a sheet and not an alert, a toast or a banner. An alert's convention is "we
//  need a decision from you", and there is none to make, so it reads as an error; it
//  is also 238pt wide, which gives Korean three lines at the larger type sizes. A
//  toast or a banner can swallow the second sentence, and the second sentence is the
//  entire reason for showing this. There is no Restore button here: after a refund
//  it would return nothing.
//
//  The title is 17/semibold and deliberately not the 25/600 state-headline slot —
//  that slot overflows in English, Ukrainian, German and Polish at xxLarge.
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
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(theme.sheetBg)
                .shadow(color: theme.cardShadow, radius: 24, x: 0, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
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
        // The cause is never named, and no locale mentions money: one key covers
        // both a refund and someone leaving a Family Sharing group.
        case .entitlementRevoked: return strings.Pro.revokedBody
        case let .goalChanged(hours): return strings.Pro.goalChangedBody(strings.Duration.goalHours(hours))
        }
    }
}
