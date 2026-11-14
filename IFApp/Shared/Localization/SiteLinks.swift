//
//  SiteLinks.swift
//  IFApp
//

import Foundation

enum SiteLinks {
    private static let root = "https://leonif.github.io/if24-site"

    static var privacyPolicy: URL {
        URL(string: [root, sitePath, "privacy.html"].filter { !$0.isEmpty }.joined(separator: "/"))!
    }

    private static var sitePath: String {
        switch Bundle.main.preferredLocalizations.first {
        case "uk": return "uk"
        case "de": return "de"
        case "es": return "es"
        case "fr": return "fr"
        case "pl": return "pl"
        case "ja": return "ja"
        case "ko": return "ko"
        case "zh-Hans": return "zh"
        case "ar": return "ar"
        default: return ""
        }
    }
}
