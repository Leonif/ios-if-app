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
//  Every vertical slot is a `minHeight`. A `frame(height:)` on any slot that carries
//  text would clip Japanese and Korean at the default type size, straight out of the
//  box. The floors themselves are English measurements, so on a column with no room
//  to spare they step aside for what the text actually took — see `Metrics`.
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
    ///
    /// Three candidates of the same column, first that fits wins.
    ///
    /// The offer was drawn at 390 × 844 (`IF24 Pro Offer.dc.html`). A 375 × 667
    /// screen is 177pt shorter, and in the text-heavier locales the reading matter
    /// outgrows it: at default type size the third benefit — the one the framing
    /// line does not introduce — ended up under the bottom fade in en, de, ja, uk
    /// and fr, its caption off-screen. In Japanese the fade reached the row's title
    /// too, and a dimmed dot over a dimmed title reads as a disabled benefit rather
    /// than a cut one — which is how it was reported.
    ///
    /// `.roomy` is the handoff's default frame, unchanged — every screen that fits
    /// it still gets exactly the layout the reference frames were verified against.
    /// `.tight` is the handoff's *own* answer to a column that has run out of room:
    /// the overflow frame (group E, "S1 · xxLarge") tightens the same three gaps
    /// and nothing else. The scrolling candidate is the floor under both: at xxLarge
    /// — the ceiling the app pins Dynamic Type to, `AppFlowView.swift:69` — no set of
    /// gaps fits the longer locales, and the fade over a scrolling region is what
    /// that frame draws.
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

    /// The vertical numbers of the column, and the only thing that separates a
    /// screen with room from one without.
    ///
    /// The two slot floors are English measurements — `spec.md` gives them as
    /// "Title slot height 40" and "Body slot min-height 56" — and the same spec
    /// says in as many words that its pt values "come from Hanken metrics and do
    /// not transfer" to ar/ja/ko/zh/uk. They hold the grid steady across the six
    /// states while there is room to hold it; when there is not, a one-line
    /// Japanese framing line reserving two English lines of empty space is 25pt
    /// taken from the benefit list directly below it.
    private struct Metrics {
        /// Close control to title.
        let closeGap: CGFloat
        /// Body slot to the first benefit.
        let listGap: CGFloat
        /// Reading matter to the price block — a gap that cannot collapse, so a
        /// clipped last benefit never touches the price.
        let priceGap: CGFloat
        let titleFloor: CGFloat
        let bodyFloor: CGFloat

        /// Group A, "S1": close margin-bottom 10, list margin-top 26, price block
        /// `margin-top: auto` (the 26 is this app's floor under an elastic gap).
        static let roomy = Metrics(closeGap: 10, listGap: 26, priceGap: 26,
                                   titleFloor: 40, bodyFloor: 56)
        /// Group E, "S1 · xxLarge": close margin-bottom 6, list margin-top 20,
        /// price block padding-top 12.
        static let tight = Metrics(closeGap: 6, listGap: 20, priceGap: 12,
                                   titleFloor: 0, bodyFloor: 0)
    }

    /// Close above, price and button below, the reading matter between them. The
    /// two controls are never what goes off-screen: at xxLarge in German the title
    /// takes two lines and the S4 body four, and a single scroll
    /// view over the whole column would carry Close off the top and Buy off the
    /// bottom at the same moment. Both have to be reachable in one gesture at any
    /// size.
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
                // Outside any scrolling region, so the gap is a floor and the slack
                // above the price block belongs to the reading matter, not to a
                // fixed offset.
                Spacer(minLength: metrics.priceGap)
                bottomBlock
            }
        }
    }

    /// Title, body and the benefit list.
    private func reading(_ metrics: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSlot(metrics)
            bodySlot(metrics)
            benefitList(metrics)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The same reading matter when no set of gaps can fit it — the accessibility
    /// type sizes. Scrolls, and its bottom edge dissolves over `Self.fadeHeight`
    /// instead of being cut: the handoff's overflow frame draws a 36pt gradient to
    /// the background over the scrolling region.
    private func scrollingReading(_ metrics: Metrics) -> some View {
        ScrollView(.vertical) {
            reading(metrics)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The fade is drawn over the viewport, so the last line has to be able to
        // travel out from under it — otherwise scrolling to the end leaves the very
        // words the fade exists to promise half-transparent. The inset is exactly the
        // fade's height and only ever adds scrollable slack.
        .contentMargins(.bottom, Self.fadeHeight, for: .scrollContent)
        // As a mask rather than the handoff's opaque `--bg` overlay: the offer's
        // surface carries the phase tint (`PaywallBackdrop`), and a flat rectangle of
        // the base colour would print a pale block over it. Fading the content's own
        // alpha is the same picture on any backdrop.
        .mask {
            VStack(spacing: 0) {
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: Self.fadeHeight)
            }
        }
    }

    /// Height of the bottom fade over the scrolling region — 36pt, from the overflow
    /// frame in `IF24 Pro Offer.dc.html` (the number is not in `spec.md`).
    private static let fadeHeight: CGFloat = 36

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

    // MARK: Benefits

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

    /// A phase dot, or — once the purchase is in — a green check in a box of the
    /// same width, so the list does not reflow when the state changes.
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

    // MARK: Price, wedge, actions

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
                // The wedge. It is the product's whole argument and the mockup has
                // no slot for it in any of the six frames — an omission, not a
                // decision, so it goes where the copy says: under the badge, above
                // the button, at body size.
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
            // Flat on the track colour with no green shadow: dimmed green reads as
            // "tap harder", and there is nothing here to tap harder at.
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

    /// S6, whichever of the three ways the right arrived. The frame is one frame:
    /// the badge, the check-marks in place of the phase dots and the Done button do
    /// not know what paid for them.
    private var isGranted: Bool {
        if case .granted = state { return true }
        return false
    }

    /// The offer keeps its own Restore link everywhere except the two states where
    /// Restore already owns a button of its own.
    private var showsRestoreLink: Bool {
        state != .unverified && !isGranted
    }

    private var title: String {
        switch state {
        case .offer, .purchasing: return strings.Pro.headline
        case .failed: return strings.Pro.failedTitle
        case .awaitingApproval: return strings.Pro.awaitingTitle
        case .unverified: return strings.Pro.unverifiedTitle
        // One frame, three headlines. This is the whole of what the source changes
        // on screen — and the reason a purchase no longer has to be inferred from a
        // capsule that disappeared.
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
            // Two strings, one frame. The network case names the network, because
            // "something went wrong" sends a person to look for a fault that is not
            // theirs and not ours.
            return reason == .network ? strings.Pro.failedBodyNetwork : strings.Pro.failedBodyGeneral
        case .awaitingApproval: return strings.Pro.awaitingBody
        case .unverified: return strings.Pro.unverifiedBody
        case let .granted(source):
            // A restore has nothing to say about money — it moved none. The two paid
            // sources name the sum, and fall back to naming where to find it rather
            // than to an empty line or a live `%@`.
            guard source != .restored else { return strings.Pro.restoredBody }
            return price.map(strings.Pro.purchasedBody) ?? strings.Pro.purchasedBodyNoPrice
        }
    }

    /// The framing line introduces the lead benefit, so it moves with it. One line per
    /// lead, decided by the same expression that orders the list below — two
    /// expressions would let the sentence introduce a benefit the list no longer
    /// starts with, which is what the export lock did: a padlock on "History as CSV"
    /// opened an offer whose first sentence was about the length of a plan.
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
        // Arriving from a broken streak, the protected day leads: it is the thing
        // that just failed. From the locked export the export leads, for the stronger
        // version of the same reason — the person did not merely see that benefit
        // fail, they asked for it by name. Everywhere else a person has never seen a
        // streak badge, and a freeze would be insurance against an event they do not
        // know exists.
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

    /// The wedge dims with the price block rather than on its own ladder (PW-U4).
    /// Left at `--secondary` it became the darkest thing on the screen in exactly the
    /// states where the price above it is standing back — and the wedge is an
    /// argument for the price, so it cannot outrank it.
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
                // The handoff writes the tint as one CSS declaration:
                // `radial-gradient(130% 55% at 50% 0%, phase 16%, transparent 72%)`.
                // Those two numbers are *radii* — 1.3 screen widths across and 0.55
                // screen heights down from a centre sitting on the top edge — so the
                // ellipse's own box is twice each of them, and the strong end of the
                // gradient has to land on the top edge of the screen.
                //
                // It shipped with the radii used as the box (`1.3w × 0.55h`) and the
                // colour at `.top` of that box. Positioned at `y: 0` the box is
                // centred on the top edge, which put the gradient's core a quarter of
                // a screen *above* the screen: what reached the frame was the faded
                // tail, measured at 5-7% where the handoff asks for 16%, and gone by
                // a sixth of the way down. The phase was in the picture and could not
                // be seen — PW-U3 read that as the feature being absent.
                //
                // Drawn as a circular ramp squashed into the ellipse rather than with
                // `EllipticalGradient`, because the CSS ramp is linear in alpha and
                // ends at a stated fraction of the radius: `endRadiusFraction` is a
                // fraction of a size SwiftUI does not name, and measured against the
                // handoff it ran a third of a screen long. `startRadius`/`endRadius`
                // are points, and the 72% stop is then the number from the CSS rather
                // than a value fitted to it.
                let radius = geo.size.width * 1.3
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: phaseColor.opacity(theme.isDark ? 0.22 : 0.16), location: 0),
                        // The far stop keeps the phase's hue and drops only its alpha:
                        // fading to `.clear` fades towards transparent *black*, which
                        // prints a grey haze halfway down the light theme.
                        .init(color: phaseColor.opacity(0), location: 0.72),
                        .init(color: phaseColor.opacity(0), location: 1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
                .frame(width: radius * 2, height: radius * 2)
                .scaleEffect(x: 1, y: geo.size.height * 0.55 / radius)
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
