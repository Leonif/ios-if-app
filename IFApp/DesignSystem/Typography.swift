//
//  Typography.swift
//  IFApp
//

import SwiftUI

extension Font {
    static func bricolage(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("Bricolage Grotesque", size: size).weight(weight)
    }

    static func hanken(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Hanken Grotesk", size: size).weight(weight)
    }
}

private struct OverlineTracking: ViewModifier {
    let value: CGFloat
    @Environment(\.layoutDirection) private var layoutDirection

    private var suppressed: Bool {
        layoutDirection == .rightToLeft || Locale.current.language.languageCode?.identifier == "ko"
    }

    func body(content: Content) -> some View {
        content.tracking(suppressed ? 0 : value)
    }
}

private struct DisplayTracking: ViewModifier {
    let value: CGFloat
    @Environment(\.layoutDirection) private var layoutDirection

    private var suppressed: Bool {
        layoutDirection == .rightToLeft || Locale.current.language.languageCode?.identifier == "ko"
    }

    func body(content: Content) -> some View {
        content.tracking(suppressed ? 0 : value)
    }
}

extension View {
    func overlineTracking(_ value: CGFloat) -> some View {
        modifier(OverlineTracking(value: value))
    }

    func displayTracking(_ size: CGFloat, _ em: CGFloat) -> some View {
        modifier(DisplayTracking(value: size * em))
    }
}

enum Typography {
    static let timerNumerals = Font.bricolage(66)
    static let timerSeconds = Font.bricolage(29)
    static let completeNumerals = Font.bricolage(50)
    static let screenTitle = Font.bricolage(19)
    static let sheetTitle = Font.bricolage(20)
    static let phaseName = Font.hanken(16, .semibold)
    static let editorial = Font.hanken(16.5, .regular)
    static let buttonLabel = Font.hanken(17, .bold)
    static let statValue = Font.hanken(15, .bold)
    static let statOverline = Font.hanken(10.5, .semibold)
    static let chip = Font.hanken(13, .semibold)
    static let timelineLabel = Font.hanken(10.5, .semibold)
    static let planRatio = Font.hanken(15, .bold)
    static let planCaption = Font.hanken(13, .medium)
}
