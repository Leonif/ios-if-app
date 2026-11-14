import SwiftUI

struct SourceArticle: Identifiable {
    let id: Int
    let title: String
    let citation: String
    let credit: String
    let kind: String
    let finding: String
    let url: URL

    static var all: [SourceArticle] {
        [
            .init(id: 0, title: SourceReaderStrings.one_title, citation: "Glycogen and its metabolism: some new developments and old themes",
                  credit: "Roach et al. · Biochemical Journal · 2012", kind: SourceReaderStrings.review,
                  finding: SourceReaderStrings.one_body,
                  url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/22248338/")!),
            .init(id: 1, title: SourceReaderStrings.two_title, citation: "Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial",
                  credit: "Trepanowski et al. · JAMA Internal Medicine · 2017", kind: SourceReaderStrings.clinical,
                  finding: SourceReaderStrings.two_body,
                  url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/28459931/")!),
            .init(id: 2, title: SourceReaderStrings.three_title, citation: "Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase",
                  credit: "Byun et al. · Nature Communications · 2020", kind: SourceReaderStrings.lab,
                  finding: SourceReaderStrings.three_body,
                  url: URL(string: "https://www.nature.com/articles/s41467-020-14384-z")!),
            .init(id: 3, title: SourceReaderStrings.four_title, citation: "Intermittent Fasting and Metabolic Health",
                  credit: "Vasim et al. · Nutrients · 2022", kind: SourceReaderStrings.review,
                  finding: SourceReaderStrings.four_body,
                  url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/")!)
        ]
    }
}

private struct ArticleFootOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

struct SourceArticleView: View {
    let article: SourceArticle
    let onOpenOriginal: (URL) -> Void
    let onReachedEnd: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var reportedEnd = false

    private static let scrollSpace = "source.article.scroll"

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        NavigationStack {
            GeometryReader { viewport in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(SourceReaderStrings.kicker)
                                .font(.hanken(12, .semibold))
                                .foregroundStyle(theme.deep)
                            Text(article.title)
                                .font(.bricolage(30, .semibold))
                                .foregroundStyle(theme.ink)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("source.article.title")
                            Text(article.kind)
                                .font(.hanken(14, .medium))
                                .foregroundStyle(theme.mut)
                            Text(article.credit)
                                .font(.hanken(12))
                                .foregroundStyle(theme.mut)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        Rectangle().fill(theme.deep).frame(width: 48, height: 3)
                        section(SourceReaderStrings.findings, body: article.finding, theme: theme)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(SourceReaderStrings.editorial)
                                .font(.hanken(12)).foregroundStyle(theme.mut)
                            Text(article.citation)
                                .font(.hanken(13)).foregroundStyle(theme.mut)
                                .environment(\.layoutDirection, .leftToRight)
                            Button { onOpenOriginal(article.url) } label: {
                                HStack {
                                    Text(SourceReaderStrings.original)
                                        .font(.hanken(16, .medium))
                                    Spacer(minLength: 12)
                                    Image(systemName: "arrow.up.forward")
                                }
                                .foregroundStyle(theme.deep)
                                .frame(minHeight: 48)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("source.article.original")
                        }
                        endMarker
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 600, alignment: .leading)
                    .padding(24)
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: Self.scrollSpace)
                .background(theme.sheetBg.ignoresSafeArea())
                .onPreferenceChange(ArticleFootOffsetKey.self) { footOffset in
                    guard !reportedEnd, footOffset <= viewport.size.height else { return }
                    reportedEnd = true
                    onReachedEnd()
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button { dismiss() } label: { Image(systemName: "xmark") }
                            .accessibilityLabel(strings.Pro.close)
                            .accessibilityIdentifier("source.article.close")
                    }
                }
            }
        }
    }

    private var endMarker: some View {
        Color.clear
            .frame(height: 1)
            .background(GeometryReader { proxy in
                Color.clear.preference(
                    key: ArticleFootOffsetKey.self,
                    value: proxy.frame(in: .named(Self.scrollSpace)).minY
                )
            })
    }

    private func section(_ title: String, body: String, theme: ThemeTokens) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.hanken(14, .semibold)).foregroundStyle(theme.deep)
                .accessibilityAddTraits(.isHeader)
            Text(body).font(.hanken(17)).lineSpacing(5).foregroundStyle(theme.ink)
        }
    }
}
