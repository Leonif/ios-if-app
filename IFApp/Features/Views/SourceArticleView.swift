import SwiftUI

/// Bundled editorial content. Reading never requires a network connection.
struct SourceArticle: Identifiable {
    let id: Int
    let title: String
    let citation: String
    let credit: String
    let kind: String
    let finding: String
    let limitation: String
    let url: URL

    static var all: [SourceArticle] {
        [
            .init(id: 0, title: SourceReaderStrings.one_title, citation: "Glycogen and its metabolism: some new developments and old themes",
                  credit: "Roach et al. · Biochemical Journal · 2012", kind: SourceReaderStrings.review,
                  finding: SourceReaderStrings.one_body, limitation: SourceReaderStrings.one_limit,
                  url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/22248338/")!),
            .init(id: 1, title: SourceReaderStrings.two_title, citation: "Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial",
                  credit: "Trepanowski et al. · JAMA Internal Medicine · 2017", kind: SourceReaderStrings.clinical,
                  finding: SourceReaderStrings.two_body, limitation: SourceReaderStrings.two_limit,
                  url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/28459931/")!),
            .init(id: 2, title: SourceReaderStrings.three_title, citation: "Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase",
                  credit: "Byun et al. · Nature Communications · 2020", kind: SourceReaderStrings.lab,
                  finding: SourceReaderStrings.three_body, limitation: SourceReaderStrings.three_limit,
                  url: URL(string: "https://www.nature.com/articles/s41467-020-14384-z")!),
            .init(id: 3, title: SourceReaderStrings.four_title, citation: "Intermittent Fasting and Metabolic Health",
                  credit: "Vasim et al. · Nutrients · 2022", kind: SourceReaderStrings.review,
                  finding: SourceReaderStrings.four_body, limitation: SourceReaderStrings.four_limit,
                  url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/")!)
        ]
    }
}

struct SourceArticleView: View {
    let article: SourceArticle
    let onOpenOriginal: (URL) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        NavigationStack {
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
                    section(SourceReaderStrings.limits, body: article.limitation, theme: theme)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(theme.backgroundBase))
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
                        Text(strings.About.medicalNote)
                            .font(.hanken(12)).foregroundStyle(theme.mut)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 600, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(theme.sheetBg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(strings.Pro.close)
                        .accessibilityIdentifier("source.article.close")
                }
            }
        }
    }

    private func section(_ title: String, body: String, theme: ThemeTokens) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.hanken(14, .semibold)).foregroundStyle(theme.deep)
                .accessibilityAddTraits(.isHeader)
            Text(body).font(.hanken(17)).lineSpacing(5).foregroundStyle(theme.ink)
        }
    }
}
