//
//  PaywallView.swift
//  IFApp
//

import SwiftUI

struct PaywallView: View {
    let state: OfferState
    let price: String?
    let trigger: PaywallTrigger
    let theme: ThemeTokens
    let showsNothingToRestore: Bool

    let onBuy: () -> Void
    let onRestore: () -> Void
    let onPrivacy: () -> Void
    let onClose: () -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            column(.roomy, scrolls: false)
            column(.tight, scrolls: false)
            column(.tight, scrolls: true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct Metrics {
        let closeGap: CGFloat
        let listGap: CGFloat
        let priceGap: CGFloat
        let titleFloor: CGFloat
        let bodyFloor: CGFloat

        static let roomy = Metrics(closeGap: 10, listGap: 26, priceGap: 26,
                                   titleFloor: 40, bodyFloor: 56)
        static let tight = Metrics(closeGap: 6, listGap: 20, priceGap: 12,
                                   titleFloor: 0, bodyFloor: 0)
    }

    private func column(_ metrics: Metrics, scrolls: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            closeRow
                .padding(.bottom, metrics.closeGap)
            if scrolls {
                scrollingReading(metrics)
                bottomBlock
                    .padding(.top, metrics.priceGap)
            } else {
                reading(metrics)
                Spacer(minLength: metrics.priceGap)
                bottomBlock
            }
        }
    }

    private func reading(_ metrics: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSlot(metrics)
            bodySlot(metrics)
            benefitList(metrics)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scrollingReading(_ metrics: Metrics) -> some View {
        ScrollView(.vertical) {
            reading(metrics)
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentMargins(.bottom, Self.fadeHeight, for: .scrollContent)
        .mask {
            VStack(spacing: 0) {
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: Self.fadeHeight)
            }
        }
    }

    private static let fadeHeight: CGFloat = 36

    // MARK: - Header

    private var closeRow: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isBusy ? theme.faint : theme.sec)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .opacity(isBusy ? 0.5 : 1)
            .disabled(isBusy)
            .accessibilityLabel(strings.Pro.close)
            .accessibilityIdentifier("paywall.close")
        }
        .padding(.trailing, -10)
    }

    private func titleSlot(_ metrics: Metrics) -> some View {
        Text(title)
            .font(.bricolage(25, .semibold))
            .displayTracking(25, -0.015)
            .foregroundColor(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: metrics.titleFloor, alignment: .leading)
    }

    private func bodySlot(_ metrics: Metrics) -> some View {
        Text(bodyText)
            .font(.hanken(17))
            .lineSpacing(17 * 0.3)
            .foregroundColor(theme.sec)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: metrics.bodyFloor, alignment: .topLeading)
            .padding(.top, 6)
    }

    // MARK: - Benefits

    private func benefitList(_ metrics: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(benefits) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    marker(benefit.dot)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(.hanken(16, .medium))
                            .foregroundColor(theme.ink)
                        Text(benefit.body)
                            .font(.hanken(15))
                            .lineSpacing(15 * 0.25)
                            .foregroundColor(theme.sec)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, metrics.listGap)
        .opacity(listOpacity)
    }

    @ViewBuilder
    private func marker(_ dot: Color) -> some View {
        if isGranted {
            Image("pro-check")
                .renderingMode(.template)
                .foregroundColor(theme.deep)
                .frame(width: 18, height: 18)
                .background(Circle().fill(theme.primaryButtonBg.opacity(0.18)))
                .padding(.top, 1)
        } else {
            Circle()
                .fill(dot)
                .frame(width: 7, height: 7)
                .padding(.leading, 5.5)
                .padding(.trailing, 5.5)
                .padding(.top, 8)
        }
    }

    // MARK: - Price, wedge, actions

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isGranted {
                Text(strings.Pro.proActiveBadge)
                    .font(.hanken(13, .medium))
                    .foregroundColor(theme.deep)
                    .padding(.bottom, 8)
            } else {
                if let price {
                    Text(price)
                        .font(.bricolage(28, .semibold))
                        .monospacedDigit()
                        .displayTracking(28, -0.01)
                        .foregroundColor(priceColor)
                        .lineLimit(1)
                        .accessibilityIdentifier("paywall.price")
                }
                Text(strings.Pro.oneTimePurchase)
                    .font(.hanken(13, .medium))
                    .foregroundColor(badgeColor)
                Text(strings.Pro.wedge)
                    .font(.hanken(17))
                    .foregroundColor(wedgeColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 24, alignment: .leading)
                    .padding(.bottom, 8)
            }

            primaryAction
            if state == .unverified { secondaryBuy }
            serviceBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch state {
        case .offer:
            OfferButton(title: strings.Pro.buy, theme: theme, action: onBuy)
                .accessibilityIdentifier("paywall.buy")
        case .purchasing:
            OfferButton(title: strings.Pro.confirming, theme: theme, showsSpinner: true, action: {})
                .disabled(true)
        case .failed:
            OfferButton(title: strings.Pro.tryAgain, theme: theme, action: onBuy)
                .accessibilityIdentifier("paywall.buy")
        case .awaitingApproval:
            OfferButton(title: strings.Pro.buy, theme: theme, isDisabled: true, action: {})
                .disabled(true)
        case .unverified:
            OfferButton(title: strings.Pro.restoreFull, theme: theme, action: onRestore)
                .accessibilityIdentifier("paywall.restore")
        case .granted:
            OfferButton(title: strings.Pro.restoredDone, theme: theme, action: onClose)
                .accessibilityIdentifier("paywall.done")
        }
    }

    private var secondaryBuy: some View {
        Button(action: onBuy) {
            Text(strings.Pro.buy)
                .font(.hanken(16, .semibold))
                .foregroundColor(theme.deep)
                .padding(.horizontal, 26)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16).stroke(theme.secLine, lineWidth: 1)
                )
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("paywall.buy")
    }

    private var serviceBlock: some View {
        HStack(spacing: 12) {
            if showsNothingToRestore {
                Text(strings.Pro.nothingToRestore)
                    .font(.hanken(13, .medium))
                    .foregroundColor(theme.mut)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            } else {
                if showsRestoreLink {
                    Button(action: onRestore) {
                        Text(strings.Pro.restoreShort)
                            .font(.hanken(13, .medium))
                            .foregroundColor(isBusy ? theme.sec : theme.deep)
                    }
                    .buttonStyle(.plain)
                    .disabled(isBusy)
                    .accessibilityIdentifier("paywall.restoreLink")
                    Rectangle()
                        .fill(theme.faint)
                        .frame(width: 1, height: 12)
                }
                Button(action: onPrivacy) {
                    Text(strings.Pro.privacyShort)
                        .font(.hanken(13, .medium))
                        .foregroundColor(isBusy ? theme.sec : theme.deep)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .opacity(isBusy ? 0.45 : 1)
    }

    // MARK: - Derivations

    private struct Benefit: Identifiable {
        let id: Int
        let title: String
        let body: String
        let dot: Color
    }

    private var isBusy: Bool { state == .purchasing }

    private var isGranted: Bool {
        if case .granted = state { return true }
        return false
    }

    private var showsRestoreLink: Bool {
        state != .unverified && !isGranted
    }

    private var title: String {
        switch state {
        case .offer, .purchasing: return strings.Pro.headline
        case .failed: return strings.Pro.failedTitle
        case .awaitingApproval: return strings.Pro.awaitingTitle
        case .unverified: return strings.Pro.unverifiedTitle
        case let .granted(source):
            switch source {
            case .purchased: return strings.Pro.purchasedTitle
            case .restored: return strings.Pro.restoredTitle
            case .approved: return strings.Pro.approvedTitle
            }
        }
    }

    private var bodyText: String {
        switch state {
        case .offer, .purchasing: return framingLine
        case let .failed(reason):
            return reason == .network ? strings.Pro.failedBodyNetwork : strings.Pro.failedBodyGeneral
        case .awaitingApproval: return strings.Pro.awaitingBody
        case .unverified: return strings.Pro.unverifiedBody
        case let .granted(source):
            guard source != .restored else { return strings.Pro.restoredBody }
            return price.map(strings.Pro.purchasedBody) ?? strings.Pro.purchasedBodyNoPrice
        }
    }

    private var framingLine: String {
        switch trigger {
        case .streakBreak: return strings.Pro.framingProtectedDay
        case .historyExport: return strings.Pro.framingExport
        default: return strings.Pro.framingCustom
        }
    }

    private var benefits: [Benefit] {
        let custom = Benefit(id: 0, title: strings.Pro.benefitCustomTitle,
                             body: strings.Pro.benefitCustomBody, dot: Phase.fat.color)
        let export = Benefit(id: 1, title: strings.Pro.benefitExportTitle,
                             body: strings.Pro.benefitExportBody, dot: Phase.ketosis.color)
        let freeze = Benefit(id: 2, title: strings.Pro.benefitFreezeTitle,
                             body: strings.Pro.benefitFreezeBody, dot: Phase.autophagy.color)
        switch trigger {
        case .streakBreak: return [freeze, custom, export]
        case .historyExport: return [export, custom, freeze]
        default: return [custom, export, freeze]
        }
    }

    private var listOpacity: Double {
        switch state {
        case .purchasing: return 0.55
        case .awaitingApproval: return 0.7
        default: return 1
        }
    }

    private var priceColor: Color {
        switch state {
        case .purchasing, .awaitingApproval: return theme.mut
        case .unverified: return theme.sec
        default: return theme.ink
        }
    }

    private var wedgeColor: Color {
        switch state {
        case .purchasing, .awaitingApproval: return theme.mut
        default: return theme.sec
        }
    }

    private var badgeColor: Color {
        switch state {
        case .purchasing, .awaitingApproval: return theme.mut
        default: return theme.deep
        }
    }
}

private struct OfferButton: View {
    let title: String
    let theme: ThemeTokens
    var isDisabled: Bool = false
    var showsSpinner: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if showsSpinner { Spinner(color: theme.primaryButtonText) }
                Text(title)
                    .font(.hanken(17, .semibold))
                    .foregroundColor(isDisabled ? theme.faint : theme.primaryButtonText)
            }
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDisabled ? theme.ringTrack : theme.primaryButtonBg)
            )
            .shadow(color: isDisabled ? .clear : shadowColor,
                    radius: theme.isDark ? 13 : 10, x: 0, y: theme.isDark ? 10 : 8)
        }
        .buttonStyle(.pressable)
    }

    private var shadowColor: Color {
        theme.isDark ? .black.opacity(0.45) : theme.primaryButtonBg.opacity(0.30)
    }
}

private struct Spinner: View {
    let color: Color
    @State private var angle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.35), lineWidth: 2)
            Circle().trim(from: 0, to: 0.25).stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: 17, height: 17)
        .rotationEffect(.degrees(angle))
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}
