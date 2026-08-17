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
    /// The quiet fill — the material the handoff gives to "this has weight, and it
    /// is not an action". A rank of its own rather than a reuse of `secBg` or
    /// `iconCircle`: those two are white-on-white and a green wash, and neither
    /// carries `ink` at the contrast this rank owes. The Pro control in the header is
    /// its first caller; the reversible-action surfaces of the consequence sheets are
    /// drawn on it too and land next, which is why it is a token and not a colour
    /// spelled out inside one view.
    let surfaceQuiet: Color
    /// The hairline that keeps a control drawn on `surfaceQuiet` from dissolving into
    /// the sheet behind it. Its own value rather than `surfaceLine`: the quiet fill
    /// sits almost on top of the sheet colour, so the edge it needs is lighter than
    /// the one a card draws against the app background, and reusing the card's would
    /// have redrawn a button as a panel.
    let surfaceQuietLine: Color
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
        surfaceQuiet: Color(hex: "#EFEDE6"),
        surfaceQuietLine: Color(.sRGB, red: 78/255, green: 90/255, blue: 70/255, opacity: 0.10),
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
        surfaceQuiet: Color(hex: "#23252B"),
        surfaceQuietLine: .whiteAlpha(0.07),
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

    // MARK: Eating window

    /// The open eating window's backdrop. The window is a pause between fasts, not a
    /// stage of one: the phase timeline is deliberately absent from this state, so a
    /// phase-derived tint would be inconsistent with it. Neutral green instead.
    ///
    /// Deliberately its own value rather than a reuse of `historyBackground` — two
    /// different things that happen to land on the same green today.
    var eatingWindowBackground: RadialGradient {
        RadialGradient(
            colors: [Color(hex: isDark ? "#151C17" : "#E9EEE6"), backgroundBase],
            center: UnitPoint(x: 0.5, y: isDark ? 0.03 : 0.01),
            startRadius: 0,
            endRadius: isDark ? 520 : 430
        )
    }

    // MARK: History screen

    /// The history backdrop. Same treatment as the timer's phase tint, but neutral
    /// green — history has no active phase to react to.
    var historyBackground: RadialGradient {
        RadialGradient(
            colors: [Color(hex: isDark ? "#151C17" : "#E9EEE6"), backgroundBase],
            center: UnitPoint(x: 0.5, y: isDark ? 0.03 : 0.01),
            startRadius: 0,
            endRadius: isDark ? 520 : 430
        )
    }

    /// Backdrop of an expanded record's detail panel.
    var historyDetailBg: Color {
        isDark ? .whiteAlpha(0.04) : Color(.sRGB, red: 110/255, green: 139/255, blue: 106/255, opacity: 0.055)
    }

    /// The hairline ghost rings in the empty state.
    var historyGhostLine: Color {
        isDark ? .whiteAlpha(0.13) : Color(.sRGB, red: 78/255, green: 90/255, blue: 70/255, opacity: 0.16)
    }

    /// The phase name under a record's plan pill — the phase color pulled toward
    /// the text color so it reads as a label, not as a second accent.
    func historyPhaseLabel(_ phase: Color) -> Color {
        isDark ? phase.mix(.white, 0.38) : phase.mix(Color(hex: "#2A2A26"), 0.34)
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
