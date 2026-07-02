//
//  SourcesView.swift
//  IFApp
//
//  Scientific sources behind the fasting phases. Redesigned into the Verdant
//  system: a grouped "editorial list" card of studies + a soft medical note.
//

import SwiftUI
import UIKit

struct SourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private struct Source { let title: String; let url: String }
    private var sources: [Source] {
        [
            Source(title: strings.Sources.source1, url: "https://pubmed.ncbi.nlm.nih.gov/22248338/"),
            Source(title: strings.Sources.source2, url: "https://pubmed.ncbi.nlm.nih.gov/28459931/"),
            Source(title: strings.Sources.source3, url: "https://www.nature.com/articles/s41467-020-14384-z"),
            Source(title: strings.Sources.source4, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/"),
        ]
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        ZStack {
            theme.backgroundBase.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                header(theme)
                ScrollView {
                    card(theme)
                }
                disclaimer(theme)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private func header(_ theme: ThemeTokens) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(strings.Sources.title)
                    .font(.bricolage(26))
                    .foregroundColor(theme.ink)
                Text(strings.Sources.subtitle)
                    .font(.hanken(14, .medium))
                    .foregroundColor(theme.mut)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.mut)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(theme.secBg))
            }
        }
        .padding(.top, 8)
    }

    private func card(_ theme: ThemeTokens) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sources.enumerated()), id: \.offset) { idx, source in
                Button(action: { open(source.url) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 17))
                            .foregroundColor(theme.accent)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(theme.iconCircle))
                        Text(source.title)
                            .font(.hanken(15, .semibold))
                            .foregroundColor(theme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.faint)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                if idx < sources.count - 1 {
                    Rectangle().fill(theme.surfaceLine).frame(height: 1).padding(.leading, 62)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(theme.sheetBg))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.surfaceLine, lineWidth: 1))
    }

    private func disclaimer(_ theme: ThemeTokens) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 15))
                .foregroundColor(theme.mut)
            Text(strings.Sources.disclaimerBody)
                .font(.hanken(12.5, .regular))
                .foregroundColor(theme.mut)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.surface))
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
