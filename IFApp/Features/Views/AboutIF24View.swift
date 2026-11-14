//
//  AboutIF24View.swift
//  IFApp
//

import SwiftUI

struct AboutIF24View: View {
    let status: ProRowStatus
    let showsNothingToRestore: Bool
    let onOpenOffer: () -> Void
    let onRestore: () -> Void
    let onPrivacy: () -> Void
    let onSunnah: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    let onOpenSource: (Int, URL) -> Void
    let onOpenArticle: (Int) -> Void
    let onCloseArticle: (Int, Bool) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var selectedSource: SourceArticle?
    @State private var readingArticleID: Int?
    @State private var readerReachedEnd = false
    private var sources: [SourceArticle] { SourceArticle.all }

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

                sunnahSection(theme)

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
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .background(theme.sheetBg.ignoresSafeArea())
        .sheet(item: $selectedSource, onDismiss: reportReaderClosed) { article in
            SourceArticleView(
                article: article,
                onOpenOriginal: { onOpenSource(article.id, $0) },
                onReachedEnd: { readerReachedEnd = true }
            )
        }
    }

    // MARK: - Sections

    private func proSection(_ theme: ThemeTokens) -> some View {
        groupCard(theme) {
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

    private func proRow(_ theme: ThemeTokens) -> some View {
        ViewThatFits(in: .horizontal) {
            sideBySideRow(theme)
            stackedRow(theme)
        }
        .frame(minHeight: 52)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

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

    private func sunnahSection(_ theme: ThemeTokens) -> some View {
        groupCard(theme) {
            Button(action: onSunnah) {
                HStack(spacing: 12) {
                    Text(SunnahStrings.title)
                        .font(.hanken(16, .medium))
                        .foregroundColor(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    chevron(theme)
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("about.sunnah")
        }
        .padding(.bottom, 26)
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
                    readerReachedEnd = false
                    readingArticleID = source.id
                    selectedSource = source
                    onOpenArticle(source.id)
                } label: {
                    HStack(spacing: 12) {
                        Text(source.title)
                            .font(.hanken(15))
                            .lineSpacing(15 * 0.15)
                            .foregroundColor(theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        chevron(theme)
                    }
                    .frame(minHeight: 56)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.source.\(source.id)")
                if source.id < sources.count - 1 { divider(theme) }
            }
        }
    }

    private func reportReaderClosed() {
        guard let articleID = readingArticleID else { return }
        readingArticleID = nil
        onCloseArticle(articleID, readerReachedEnd)
    }

    // MARK: - Pieces

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

    private func chevron(_ theme: ThemeTokens) -> some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(theme.mut)
    }
}

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
