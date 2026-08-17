//
//  AboutIF24View.swift
//  IFApp
//
//  What used to be the Scientific Sources sheet. The papers are still here, but they
//  are no longer what the sheet is about: the order of the sections changes its
//  class, from a science note to the app's own document. Pro first — status, the way
//  into the offer, and Restore — then privacy, then the research, with the medical
//  note closing the science section rather than sitting under a commercial row.
//
//  Restore lives in the first section a person looks in after changing phone. That is
//  the whole reason this sheet was rebuilt instead of a settings screen being added.
//

import SwiftUI

/// What the Pro row's right-hand column says. The axis is the state of the
/// entitlement — never the tier, the purchase, or the price.
enum ProRowStatus: Equatable {
    case inactive
    case active
    case awaitingApproval
    /// Nothing has been checked yet. Gating behaves as free here, but the row never
    /// says "inactive": caution earns a lock, not a claim.
    case notCheckedYet

    var label: String {
        switch self {
        case .inactive: return strings.Pro.statusInactive
        case .active: return strings.Pro.statusActive
        case .awaitingApproval: return strings.Pro.statusAwaiting
        case .notCheckedYet: return strings.Pro.statusUnverified
        }
    }

    /// Active is the one state with nothing to open — the offer must not appear for
    /// someone who already owns it, so the row loses its chevron and takes a check.
    var opensOffer: Bool { self != .active }
}

struct AboutIF24View: View {
    let status: ProRowStatus
    /// Restore ran from this sheet and found nothing. Where the status itself moved,
    /// that is the feedback; where it did not, this line is.
    let showsNothingToRestore: Bool
    let onOpenOffer: () -> Void
    let onRestore: () -> Void
    let onPrivacy: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    /// The sheet is presented, so it starts a fresh environment and does not inherit
    /// the root's `dynamicTypeSize` ceiling — the accessibility sizes reach this view
    /// for real, and one slot has to know it.
    @Environment(\.dynamicTypeSize) private var typeSize

    private struct Source: Identifiable {
        let id: Int
        let title: String
        let url: String
    }

    private var sources: [Source] {
        [
            Source(id: 0, title: strings.Sources.source1, url: "https://pubmed.ncbi.nlm.nih.gov/22248338/"),
            Source(id: 1, title: strings.Sources.source2, url: "https://pubmed.ncbi.nlm.nih.gov/28459931/"),
            Source(id: 2, title: strings.Sources.source3, url: "https://www.nature.com/articles/s41467-020-14384-z"),
            Source(id: 3, title: strings.Sources.source4, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/"),
        ]
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(strings.About.title)
                    .font(.bricolage(22, .semibold))
                    .displayTracking(22, -0.01)
                    .foregroundColor(theme.ink)
                    .padding(.bottom, 22)

                overline(strings.Pro.productName, theme)
                proSection(theme)
                caption(strings.Pro.sectionFooter, theme)

                overline(strings.Pro.privacyShort, theme)
                privacySection(theme)
                caption(strings.About.privacyFooter, theme)

                overline(strings.Sources.title, theme)
                sourcesSection(theme)

                Text(strings.About.medicalNote)
                    .font(.hanken(12))
                    .lineSpacing(12 * 0.35)
                    .foregroundColor(theme.mut)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(theme.sheetBg.ignoresSafeArea())
    }

    // MARK: Sections

    private func proSection(_ theme: ThemeTokens) -> some View {
        groupCard(theme) {
            // Active is a statement, not a door. Rendered as a plain row rather than a
            // disabled button: a disabled button greys its whole content, and the one
            // place a paying customer sees their own state would arrive dimmed.
            if status.opensOffer {
                Button(action: onOpenOffer) {
                    proRow(theme)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.pro")
            } else {
                proRow(theme)
                    .accessibilityIdentifier("about.pro")
            }

            divider(theme)

            Button(action: onRestore) {
                HStack {
                    if showsNothingToRestore {
                        // Same rule as on the offer up to the app's own type ceiling:
                        // this line does not wrap. The slot here is the narrower one —
                        // 287pt on a 375pt device, not the offer's — and at xxLarge
                        // German (106.5%) and Ukrainian (102.7%) run past it. Shrinking
                        // is the honest way out there: the line is transient and the
                        // alternative is an ellipsis in the middle of a sentence. Only
                        // those two locales ever engage it (.939 and .973), and the
                        // floor stays clear of ko and ja.
                        //
                        // Above the ceiling the same floor buys nothing. This sheet is
                        // presented, so it does not inherit the root cap and really does
                        // render at the accessibility sizes; there `nothingToRestore`
                        // needs about .78 of the slot at accessibility1 and far less
                        // higher up, so a 0.9 floor hands back exactly the ellipsis it
                        // was chosen to avoid — measured at AX5 in de, ar and ja.
                        // Wrapping costs one line of card height for the two and a half
                        // seconds the line is up, and at these sizes the Restore label
                        // it replaces is already three lines tall, so there is no
                        // single-line height left to protect.
                        Text(strings.Pro.nothingToRestore)
                            .font(.hanken(16, .medium))
                            .foregroundColor(theme.mut)
                            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                            .minimumScaleFactor(0.9)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(strings.Pro.restoreFull)
                            .font(.hanken(16, .medium))
                            .foregroundColor(theme.deep)
                    }
                    Spacer(minLength: 8)
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("about.restore")
        }
    }

    /// Label and status side by side while both fit on one line, stacked when they
    /// do not — the same move the system Settings rows make, and for the same reason.
    ///
    /// It is a layout answer to what looks like a copy problem, and it has to be:
    /// the status values are the shortest attested forms their languages have. At
    /// xxLarge — inside the app's own Dynamic Type ceiling, so no accessibility
    /// setting is needed to reach it — `Awaiting approval` already runs past the slot
    /// in four locales (de, es, pl, fr), and at the accessibility sizes Ukrainian
    /// `Неактивний` follows. Squeezed in the side-by-side layout a single long word
    /// has nowhere to break and splits mid-word against the chevron; given the row's
    /// full width it simply sits on its own line.
    ///
    /// Gating this on `isAccessibilitySize` would have missed the four locales that
    /// break first, which is why the switch is "does it fit", not "how large is the
    /// text".
    private func proRow(_ theme: ThemeTokens) -> some View {
        ViewThatFits(in: .horizontal) {
            sideBySideRow(theme)
            stackedRow(theme)
        }
        .frame(minHeight: 52)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    /// The preferred shape. Both texts are pinned to one line at their natural width
    /// so that `ViewThatFits` measures what they really need — a text allowed to wrap
    /// "fits" any width at all, and the fallback would never be chosen.
    private func sideBySideRow(_ theme: ThemeTokens) -> some View {
        HStack(spacing: 12) {
            rowLabel(theme)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                activeCheck(theme)
                statusText(theme, alignment: .trailing)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            if status.opensOffer { chevron(theme) }
        }
    }

    /// Label over value, both against the leading edge, chevron still trailing. The
    /// status gets the row's whole width here, so it wraps between words instead of
    /// inside one.
    private func stackedRow(_ theme: ThemeTokens) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                rowLabel(theme)
                HStack(spacing: 8) {
                    activeCheck(theme)
                    statusText(theme, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if status.opensOffer { chevron(theme) }
        }
        .padding(.vertical, 10)
    }

    private func rowLabel(_ theme: ThemeTokens) -> some View {
        Text(strings.Pro.productName)
            .font(.hanken(16, .medium))
            .foregroundColor(theme.ink)
    }

    /// Active is the one status that also carries a mark.
    @ViewBuilder
    private func activeCheck(_ theme: ThemeTokens) -> some View {
        if status == .active {
            Image("pro-check")
                .renderingMode(.template)
                .foregroundColor(theme.deep)
                .frame(width: 16, height: 16)
                .background(Circle().fill(theme.primaryButtonBg.opacity(0.18)))
        }
    }

    /// In Japanese the value is empty by decision — the slot then hides rather than
    /// rendering an empty `Text`, and the row's height does not move.
    @ViewBuilder
    private func statusText(_ theme: ThemeTokens, alignment: TextAlignment) -> some View {
        if !status.label.isEmpty {
            Text(status.label)
                .font(.hanken(15))
                .foregroundColor(status == .active ? theme.deep : theme.mut)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 20, alignment: alignment == .trailing ? .trailing : .leading)
                .multilineTextAlignment(alignment)
                .accessibilityIdentifier("about.pro.status")
        }
    }

    private func privacySection(_ theme: ThemeTokens) -> some View {
        groupCard(theme) {
            Button(action: onPrivacy) {
                HStack(spacing: 12) {
                    Text(strings.Pro.privacyFull)
                        .font(.hanken(16, .medium))
                        .foregroundColor(theme.ink)
                    Spacer(minLength: 8)
                    chevron(theme)
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func sourcesSection(_ theme: ThemeTokens) -> some View {
        groupCard(theme) {
            ForEach(sources) { source in
                Button {
                    if let url = URL(string: source.url) { openURL(url) }
                } label: {
                    HStack(spacing: 12) {
                        // Paper titles are English citations and stay left-to-right
                        // even in a mirrored sheet; only their alignment flips.
                        Text(source.title)
                            .font(.hanken(15))
                            .lineSpacing(15 * 0.15)
                            .foregroundColor(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        ExternalLinkArrow(color: theme.mut)
                    }
                    .frame(minHeight: 56)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if source.id < sources.count - 1 { divider(theme) }
            }
        }
    }

    // MARK: Pieces

    private func overline(_ text: String, _ theme: ThemeTokens) -> some View {
        Text(text)
            .font(.hanken(12, .semibold))
            .textCase(.uppercase)
            .overlineTracking(12 * 0.16)
            .foregroundColor(theme.mut)
            .padding(.bottom, 10)
    }

    private func caption(_ text: String, _ theme: ThemeTokens) -> some View {
        Text(text)
            .font(.hanken(13))
            .lineSpacing(13 * 0.3)
            .foregroundColor(theme.mut)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 10)
            .padding(.bottom, 26)
    }

    private func groupCard<Content: View>(_ theme: ThemeTokens,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(RoundedRectangle(cornerRadius: 16).fill(theme.backgroundBase))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.surfaceLine, lineWidth: 1))
    }

    private func divider(_ theme: ThemeTokens) -> some View {
        Rectangle()
            .fill(theme.surfaceLine)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    /// `forward`, not `right`. A disclosure indicator points on ahead, and ahead is
    /// leftward in Arabic; the absolute glyph would stay aimed right after the row
    /// mirrored, back at the label it is supposed to lead away from. `ExternalLinkArrow`
    /// below is mirrored by hand for the opposite reason — `arrow.up.right` has no
    /// semantic twin to switch to.
    private func chevron(_ theme: ThemeTokens) -> some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(theme.mut)
    }
}

/// `arrow.up.right`, mirrored by hand. SF Symbols leaves this one pointing the same
/// way in a right-to-left layout, and an outbound arrow that points into the text is
/// the one glyph on the sheet whose direction carries meaning.
private struct ExternalLinkArrow: View {
    let color: Color
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .scaleEffect(x: layoutDirection == .rightToLeft ? -1 : 1, y: 1)
    }
}
