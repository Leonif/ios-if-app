//
//  PaywallView.swift
//  IFApp
//
//  The IF24 Pro offer. Six states on one grid: they replace each other in place,
//  which is why nothing here navigates and why the price block sits at the bottom
//  of a flexible column rather than at a measured offset. Positions are computed
//  from what the text actually took, never pinned to the English measurement — the
//  S4 body is 56pt in English and 76.5pt in Korean at the same type size.
//
//  Every vertical slot is a `minHeight`. A `frame(height:)` anywhere in this file
//  would clip Japanese and Korean at the default type size, straight out of the box.
//

import SwiftUI

struct PaywallView: View {
    let state: OfferState
    /// The store's own formatted price. One string, never taken apart.
    let price: String?
    /// Which door the user came in through — it decides which benefit leads, and
    /// the framing line belongs to whichever one that is.
    let trigger: PaywallTrigger
    let theme: ThemeTokens
    /// Restore ran and found nothing: the service block says so, then goes back.
    let showsNothingToRestore: Bool

    let onBuy: () -> Void
    let onRestore: () -> Void
    let onPrivacy: () -> Void
    let onClose: () -> Void

    /// Content only — the opaque surface it sits on is `PaywallBackdrop`, drawn by the
    /// flow outside the part that switches. See that type for why.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            closeRow
            // Close above, price and button below, the reading matter between them
            // in a scroll view. The three parts are what the flexible column was
            // already doing — the list top-aligned, the price block bottom-pinned —
            // except the slack now belongs to the scroll view instead of a
            // `Spacer`, so it can go negative without anything overlapping.
            //
            // Why the two controls stay outside it: at xxLarge in German the title
            // takes two lines and the S4 body four, and a single scroll view over
            // the whole column would carry Close off the top and Buy off the bottom
            // at the same moment. Both have to be reachable in one gesture at any
            // size, and pinning them costs nothing at the sizes the screen was
            // drawn for — the layout below xxLarge is pixel-identical to the
            // `Spacer` version.
            readingBlock
            bottomBlock
                // The old `Spacer(minLength: 26)`, now a gap that cannot collapse:
                // it sits outside the scroll view, so a clipped last benefit still
                // clears the price by 26pt instead of touching it.
                .padding(.top, 26)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Title, body and the benefit list. Scrolls only when it has to: the bounce is
    /// tied to the content size, so at the sizes that fit the screen still reads as
    /// the fixed surface it is drawn as, with nothing to rubber-band.
    private var readingBlock: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                titleSlot
                bodySlot
                benefitList
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: Header

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
            // While a charge is pending the control stays exactly where it is and
            // stops responding. Removing it would move the layout under a thumb that
            // is already travelling.
            .opacity(isBusy ? 0.5 : 1)
            .disabled(isBusy)
            .accessibilityLabel(strings.Pro.close)
            .accessibilityIdentifier("paywall.close")
        }
        // The 44pt tap target overhangs the gutter by 10 so the glyph itself, not
        // its target, lines up with the content edge.
        .padding(.trailing, -10)
        .padding(.bottom, 10)
    }

    private var titleSlot: some View {
        Text(title)
            .font(.bricolage(25, .semibold))
            .displayTracking(25, -0.015)
            .foregroundColor(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }

    private var bodySlot: some View {
        Text(bodyText)
            .font(.hanken(17))
            .lineSpacing(17 * 0.3)
            .foregroundColor(theme.sec)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            .padding(.top, 6)
    }

    // MARK: Benefits

    private var benefitList: some View {
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
        .padding(.top, 26)
        .opacity(listOpacity)
    }

    /// A phase dot, or — once the purchase is in — a green check in a box of the
    /// same width, so the list does not reflow when the state changes.
    @ViewBuilder
    private func marker(_ dot: Color) -> some View {
        if state == .restored {
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

    // MARK: Price, wedge, actions

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            if state == .restored {
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
                // The wedge. It is the product's whole argument and the mockup has
                // no slot for it in any of the six frames — an omission, not a
                // decision, so it goes where the copy says: under the badge, above
                // the button, at body size.
                Text(strings.Pro.wedge)
                    .font(.hanken(17))
                    .foregroundColor(theme.sec)
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
            // Flat on the track colour with no green shadow: dimmed green reads as
            // "tap harder", and there is nothing here to tap harder at.
            OfferButton(title: strings.Pro.buy, theme: theme, isDisabled: true, action: {})
                .disabled(true)
        case .unverified:
            OfferButton(title: strings.Pro.restoreFull, theme: theme, action: onRestore)
                .accessibilityIdentifier("paywall.restore")
        case .restored:
            OfferButton(title: strings.Sheet.done, theme: theme, action: onClose)
                .accessibilityIdentifier("paywall.done")
        }
    }

    /// S5 only: Restore takes the primary slot, so Buy drops to the outline variant.
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

    /// Restore and Privacy as two views with a divider view between them — never one
    /// string with a separator inside it, which in Arabic sends the neutral character
    /// somewhere the reader is not expecting it.
    private var serviceBlock: some View {
        HStack(spacing: 12) {
            if showsNothingToRestore {
                // The line takes the whole 327pt — 375 minus the two 24pt gutters
                // above — and the divider and Privacy stand
                // down for its two and a half seconds — the same move S5 already
                // makes. Sharing the row instead would stack it at xxLarge in
                // Ukrainian and German, growing the block by 1.84pt and shrinking it
                // back: a layout animation, which the motion spec forbids outright.
                // Wrapping is not an option either — Japanese breaks onto its last
                // character, which no line-breaking rule protects.
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

    // MARK: Derivations

    private struct Benefit: Identifiable {
        let id: Int
        let title: String
        let body: String
        let dot: Color
    }

    private var isBusy: Bool { state == .purchasing }

    /// The offer keeps its own Restore link everywhere except the two states where
    /// Restore already owns a button of its own.
    private var showsRestoreLink: Bool {
        state != .unverified && state != .restored
    }

    private var title: String {
        switch state {
        case .offer, .purchasing: return strings.Pro.headline
        case .failed: return strings.Pro.failedTitle
        case .awaitingApproval: return strings.Pro.awaitingTitle
        case .unverified: return strings.Pro.unverifiedTitle
        case .restored: return strings.Pro.restoredTitle
        }
    }

    private var bodyText: String {
        switch state {
        case .offer, .purchasing: return framingLine
        case let .failed(reason):
            // Two strings, one frame. The network case names the network, because
            // "something went wrong" sends a person to look for a fault that is not
            // theirs and not ours.
            return reason == .network ? strings.Pro.failedBodyNetwork : strings.Pro.failedBodyGeneral
        case .awaitingApproval: return strings.Pro.awaitingBody
        case .unverified: return strings.Pro.unverifiedBody
        case .restored: return strings.Pro.restoredBody
        }
    }

    /// The framing line introduces the lead benefit, so it moves with it.
    private var framingLine: String {
        trigger == .streakBreak ? strings.Pro.framingProtectedDay : strings.Pro.framingCustom
    }

    private var benefits: [Benefit] {
        let custom = Benefit(id: 0, title: strings.Pro.benefitCustomTitle,
                             body: strings.Pro.benefitCustomBody, dot: Phase.fat.color)
        let export = Benefit(id: 1, title: strings.Pro.benefitExportTitle,
                             body: strings.Pro.benefitExportBody, dot: Phase.ketosis.color)
        let freeze = Benefit(id: 2, title: strings.Pro.benefitFreezeTitle,
                             body: strings.Pro.benefitFreezeBody, dot: Phase.autophagy.color)
        // Arriving from a broken streak, the protected day leads: it is the thing
        // that just failed. Everywhere else a person has never seen a streak badge,
        // and a freeze would be insurance against an event they do not know exists.
        return trigger == .streakBreak ? [freeze, custom, export] : [custom, export, freeze]
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

    private var badgeColor: Color {
        switch state {
        case .purchasing, .awaitingApproval: return theme.mut
        default: return theme.deep
        }
    }
}

/// The offer's opaque surface: the theme's base colour with the phase glow over it,
/// tinted by the phase the user came from so the offer stays attached to the screen
/// that called it.
///
/// It is a type of its own, drawn by the flow *outside* the part that switches, and
/// that is the whole point of it. The six states replace each other by identity and
/// cross-fade, and halfway through a cross-fade both layers stand at partial alpha —
/// so a background painted inside the switched layer stops being a background for the
/// length of the transition. It cost two visible glitches around a purchase: the timer
/// read through the offer on the way into `Confirming`, and again on the way out after
/// the charge went through. Anything opaque belongs on this side of the `.id`.
struct PaywallBackdrop: View {
    let phaseColor: Color
    let theme: ThemeTokens

    var body: some View {
        ZStack {
            theme.backgroundBase
            GeometryReader { geo in
                EllipticalGradient(
                    colors: [phaseColor.opacity(theme.isDark ? 0.22 : 0.16), .clear],
                    center: .top,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.72
                )
                .frame(width: geo.size.width * 1.3, height: geo.size.height * 0.55)
                .position(x: geo.size.width / 2, y: 0)
            }
        }
        .ignoresSafeArea()
    }
}

/// The offer's primary button. Its own type rather than `PrimaryButton`: this one is
/// 54pt on a 16pt radius with a 600 label, it has a disabled shape that is flat on
/// the track colour, and it can carry a spinner — none of which the footer's button
/// has any use for.
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
            // `--shadow-cta`, which is not the footer button's glow: in the dark theme
            // the handoff drops the green halo for plain black, so the button sits on
            // the surface instead of lighting it.
            .shadow(color: isDisabled ? .clear : shadowColor,
                    radius: theme.isDark ? 13 : 10, x: 0, y: theme.isDark ? 10 : 8)
        }
        .buttonStyle(.pressable)
    }

    private var shadowColor: Color {
        theme.isDark ? .black.opacity(0.45) : theme.primaryButtonBg.opacity(0.30)
    }
}

/// A three-quarter ring turning at a constant rate. Pinned left-to-right: a spinner
/// that reverses in Arabic reads as undoing rather than working.
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
