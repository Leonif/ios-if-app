//
//  FontMetricsDump.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT
import Foundation
import UIKit

enum FontMetricsDump {
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
        print(message)
    }
}
#endif
