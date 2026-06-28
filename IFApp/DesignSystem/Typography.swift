//
//  Typography.swift
//  IFApp
//
//  The two bundled families. Bricolage = display (numerals, titles); Hanken = everything else.
//  Both are variable fonts loaded by family name; weight is selected via `.weight()`.
//  Timer numerals must be tabular — apply `.monospacedDigit()` at the call site.
//

import SwiftUI

extension Font {
    /// Bricolage Grotesque — display: timer numerals, titles, big headings (handoff weight 600).
    static func bricolage(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("Bricolage Grotesque", size: size).weight(weight)
    }

    /// Hanken Grotesk — body, labels, buttons, stats (weights 400/500/600/700).
    static func hanken(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Hanken Grotesk", size: size).weight(weight)
    }
}

enum Typography {
    static let timerNumerals = Font.bricolage(66)       // tabular via .monospacedDigit()
    static let completeNumerals = Font.bricolage(50)
    static let screenTitle = Font.bricolage(19)
    static let sheetTitle = Font.bricolage(20)
    static let phaseName = Font.hanken(16, .semibold)
    static let editorial = Font.hanken(16.5, .regular)
    static let buttonLabel = Font.hanken(17, .bold)
    static let statValue = Font.hanken(15, .bold)
    static let statOverline = Font.hanken(10.5, .semibold)  // uppercase, tracking .13em at call site
    static let chip = Font.hanken(13, .semibold)
    static let timelineLabel = Font.hanken(10.5, .semibold)
    static let planRatio = Font.hanken(15, .bold)
    static let planCaption = Font.hanken(13, .medium)
}
