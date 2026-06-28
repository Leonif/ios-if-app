//
//  Theme.swift
//  IFApp
//
//  Design tokens for the two themes — Light "Mist" and Dark "Immersive" —
//  transcribed from the design handoff. Resolve with the environment colorScheme:
//    let theme = ThemeTokens.resolve(colorScheme)
//

import SwiftUI

struct ThemeTokens {
    let isDark: Bool

    // Text
    let ink: Color
    let sec: Color
    let mut: Color
    let faint: Color

    // Surfaces / lines
    let surface: Color
    let surfaceLine: Color
    let cardShadow: Color
    let ringTrack: Color
    let secBg: Color
    let secLine: Color
    let iconCircle: Color
    let iconStroke: Color
    let sheetBg: Color
    let segTrack: Color
    let segActive: Color
    let segActiveShadow: Color

    // Brand green (single primary, same role both themes)
    let accent: Color
    let deep: Color
    let primaryButtonBg: Color
    let primaryButtonText: Color

    // Phase-reactive background base + the screen backdrop tint blend
    let backgroundBase: Color

    static let light = ThemeTokens(
        isDark: false,
        ink: Color(hex: "#2C2A26"),
        sec: Color(hex: "#5C584F"),
        mut: Color(hex: "#9A958B"),
        faint: Color(hex: "#C9C4B8"),
        surface: .whiteAlpha(0.80),
        surfaceLine: Color(.sRGB, red: 78/255, green: 90/255, blue: 70/255, opacity: 0.13),
        cardShadow: Color(.sRGB, red: 70/255, green: 80/255, blue: 60/255, opacity: 0.10),
        ringTrack: Color(hex: "#E7E5DE"),
        secBg: Color(hex: "#FFFFFF"),
        secLine: Color(.sRGB, red: 78/255, green: 90/255, blue: 70/255, opacity: 0.18),
        iconCircle: Color(.sRGB, red: 110/255, green: 139/255, blue: 106/255, opacity: 0.10),
        iconStroke: Color(hex: "#8C887E"),
        sheetBg: Color(hex: "#FCFBF7"),
        segTrack: Color(.sRGB, red: 110/255, green: 139/255, blue: 106/255, opacity: 0.10),
        segActive: Color(hex: "#FFFFFF"),
        segActiveShadow: Color(.sRGB, red: 78/255, green: 90/255, blue: 70/255, opacity: 0.16),
        accent: Color(hex: "#6E8B6A"),
        deep: Color(hex: "#4F6B4A"),
        primaryButtonBg: Color(hex: "#52734D"),
        primaryButtonText: Color(hex: "#FFFFFF"),
        backgroundBase: Color(hex: "#F5F5F1")
    )

    static let dark = ThemeTokens(
        isDark: true,
        ink: Color(hex: "#F2F2F4"),
        sec: Color(hex: "#B7BAC2"),
        mut: Color(hex: "#7E828C"),
        faint: Color(hex: "#4C505A"),
        surface: .whiteAlpha(0.05),
        surfaceLine: .whiteAlpha(0.11),
        cardShadow: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.45),
        ringTrack: .whiteAlpha(0.09),
        secBg: .whiteAlpha(0.06),
        secLine: .whiteAlpha(0.16),
        iconCircle: .whiteAlpha(0.07),
        iconStroke: Color(hex: "#9CA0AA"),
        sheetBg: Color(hex: "#16171C"),
        segTrack: .whiteAlpha(0.06),
        segActive: .whiteAlpha(0.14),
        segActiveShadow: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.30),
        accent: Color(hex: "#85B97C"),
        deep: Color(hex: "#A6CE9D"),
        primaryButtonBg: Color(hex: "#79A86F"),
        primaryButtonText: Color(hex: "#0B130A"),
        backgroundBase: Color(hex: "#0A0B0E")
    )

    static func resolve(_ scheme: ColorScheme) -> ThemeTokens {
        scheme == .dark ? .dark : .light
    }

    /// Primary-button drop shadow color (button bg at 0.32 light / 0.45 dark).
    var buttonShadow: Color {
        primaryButtonBg.opacity(isDark ? 0.45 : 0.32)
    }

    // MARK: Phase-derived colors

    /// The screen background, tinted by the current phase color.
    /// Light: PALE = mix(phase, white, 0.86); Dark: DGLOW = mix(phase, base, 0.80).
    func phaseBackground(_ phaseColor: Color) -> RadialGradient {
        if isDark {
            let dglow = phaseColor.mix(backgroundBase, 0.80)
            return RadialGradient(
                colors: [dglow, backgroundBase],
                center: UnitPoint(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 520
            )
        } else {
            let pale = phaseColor.mix(.white, 0.86)
            return RadialGradient(
                colors: [pale, backgroundBase],
                center: UnitPoint(x: 0.5, y: 0.01),
                startRadius: 0,
                endRadius: 430
            )
        }
    }

    /// Next-phase chip colors (dot/text/bg/border) derived from the named phase color.
    func chip(for next: Color) -> (dot: Color, text: Color, bg: Color, border: Color) {
        if isDark {
            return (
                dot: next,
                text: next.mix(.white, 0.42),
                bg: next.mix(Color(hex: "#0A0B0E"), 0.80),
                border: next.mix(Color(hex: "#0A0B0E"), 0.60)
            )
        } else {
            return (
                dot: next,
                text: next.mix(Color(hex: "#2A2A26"), 0.46),
                bg: next.mix(.white, 0.86),
                border: next.mix(.white, 0.68)
            )
        }
    }
}
