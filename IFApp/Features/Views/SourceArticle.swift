//
//  SourceArticle.swift
//  IFApp
//

import Foundation

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
