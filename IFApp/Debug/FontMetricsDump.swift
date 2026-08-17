//
//  FontMetricsDump.swift
//  IFApp
//
//  Measurement hook: prints the real `UIFontMetrics` scaling curve of the running
//  OS to stdout and to `Documents/font-metrics.txt`. No-op unless launched with
//  "-dumpFontMetrics". Gated like the rest of `Debug/` — never compiled into release.
//
//  Why it exists. Layout questions ("does this string still fit at xxLarge?") are
//  answered by a number that only UIKit knows, and it is not a formula: the curve
//  is a table, it is not linear, and it changes between OS releases. Extrapolating
//  it from two known points was wrong by up to 2.17pt at 20pt — enough to call a
//  string safe that in fact clips. Three separate strings hit the same guessed
//  number within two days (loc + three language specialists, 17.08.2026), which is
//  why measuring became a tool instead of a one-off: the answer is needed for the
//  whole string catalog, not for one screen.
//
//  How to use it (simulator, no taps, no UI):
//
//      xcrun simctl launch --console-pty <UDID> simple-L.if-app.com -dumpFontMetrics
//      # or read the file afterwards:
//      cat "$(xcrun simctl get_app_container <UDID> simple-L.if-app.com data)/Documents/font-metrics.txt"
//
//  Optional arguments, both taking the next argv item as their value:
//
//      -dumpFontMetricsSizes 11,12,16,20   base point sizes (default 10…24 by 1)
//      -dumpFontMetricsStyle caption1      text style (default body)
//
//  The curve is asked of an injected `UITraitCollection`, not of the device's live
//  setting, so every category is reported from one launch and the simulator's own
//  text-size slider does not have to be touched (and does not have to be trusted).
//

#if DEBUG || DEVELOPMENT
import Foundation
import UIKit

enum FontMetricsDump {
    /// Every content size category, smallest first. `.unspecified` is left out — it
    /// has no scale of its own and `scaledValue` resolves it to whatever is current,
    /// which is exactly the ambiguity this hook exists to remove.
    private static let categories: [UIContentSizeCategory] = [
        .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge,
        .extraExtraExtraLarge, .accessibilityMedium, .accessibilityLarge,
        .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
        .accessibilityExtraExtraExtraLarge,
    ]

    private static let styles: [String: UIFont.TextStyle] = [
        "largeTitle": .largeTitle, "title1": .title1, "title2": .title2,
        "title3": .title3, "headline": .headline, "subheadline": .subheadline,
        "body": .body, "callout": .callout, "footnote": .footnote,
        "caption1": .caption1, "caption2": .caption2,
    ]

    static func runIfNeeded() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-dumpFontMetrics") else { return }

        func value(_ name: String) -> String? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return args[i + 1]
        }

        // An unparsable or empty list falls back to the default range rather than
        // dumping nothing: a typo in the argument must not look like "no data".
        var bases: [CGFloat] = (10...24).map { CGFloat($0) }
        if let raw = value("-dumpFontMetricsSizes") {
            let parsed = raw.split(separator: ",").compactMap { Double($0) }.map { CGFloat($0) }
            if parsed.isEmpty {
                report("font-metrics: could not parse sizes \"\(raw)\"; falling back to 10…24")
            } else {
                bases = parsed
            }
        }

        let styleName = value("-dumpFontMetricsStyle") ?? "body"
        guard let style = styles[styleName] else {
            report("font-metrics: unknown text style \"\(styleName)\"; known: \(styles.keys.sorted().joined(separator: ", "))")
            return
        }
        let metrics = UIFontMetrics(forTextStyle: style)

        var lines = [
            "UIFontMetrics(.\(styleName)) scale curve",
            "measured \(Date()) on iOS \(UIDevice.current.systemVersion)",
            "the app caps Dynamic Type at xxLarge (AppFlowView), so rows beyond it are informational",
            "",
            "category\tbase\tscaled\tratio",
        ]
        for category in categories {
            let trait = UITraitCollection(preferredContentSizeCategory: category)
            for base in bases {
                let scaled = metrics.scaledValue(for: base, compatibleWith: trait)
                lines.append(String(format: "%@\t%.0f\t%.2f\t%.4f",
                                    category.rawValue.replacingOccurrences(of: "UICTContentSizeCategory", with: ""),
                                    base, scaled, scaled / base))
            }
        }

        let text = lines.joined(separator: "\n") + "\n"
        // Printed as well as written: on a build where the container is not reachable
        // the table is still in the launch console, and a failed write says so out
        // loud instead of leaving an empty result that looks like a measurement.
        report(text)
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("font-metrics.txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            report("font-metrics: written to \(url.path)")
        } catch {
            report("font-metrics: WRITE FAILED at \(url.path): \(error)")
        }
    }

    private static func report(_ message: String) {
        // `print`, not `os.Logger`: this is a table meant to be read verbatim from
        // `simctl launch --console-pty`, and the logger's redaction plus its own
        // per-line prefix would break it into unusable pieces.
        print(message)
    }
}
#endif
