//
//  SiteLinks.swift
//  IFApp
//
//  Links out of the app into if24-site, resolved to the language the interface is
//  actually in.
//

import Foundation

enum SiteLinks {
    private static let root = "https://leonif.github.io/if24-site"

    /// The privacy policy, in the language of the interface.
    ///
    /// The language comes from `Bundle.main.preferredLocalizations`, not from the
    /// device region and not from `Locale.current.language`: that is the localization
    /// the bundle actually resolved, so it also follows the per-app language override
    /// in Settings. A reader whose interface is German gets the German policy even on
    /// a device set to region US.
    static var privacyPolicy: URL {
        URL(string: [root, sitePath, "privacy.html"].filter { !$0.isEmpty }.joined(separator: "/"))!
    }

    /// The site's directory for the current interface language. English lives at the
    /// root and so maps to an empty segment.
    ///
    /// The bundle only ships the ten localizations below, so the default arm is
    /// unreachable in practice — it is the correct answer anyway: a language we have
    /// no page for gets the English root rather than a 404.
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
