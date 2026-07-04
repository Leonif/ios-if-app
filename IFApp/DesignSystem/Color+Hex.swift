//
//  Color+Hex.swift
//  IFApp
//
//  Hex/rgba color construction and linear-RGB mixing, used by the design tokens
//  and the phase-derived colors (phase-reactive background, next-phase chip).
//

import SwiftUI
import UIKit

extension Color {
    /// `#RRGGBB` or `#RRGGBBAA` (with or without leading `#`).
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// White at a given opacity (for `rgba(255,255,255,a)` tokens).
    static func whiteAlpha(_ opacity: Double) -> Color {
        Color(.sRGB, red: 1, green: 1, blue: 1, opacity: opacity)
    }

    /// sRGB components (0...1) including alpha.
    var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }

    /// Linear RGB interpolation toward `other` by `t` (0...1). Matches handoff `mix(a,b,t)`.
    func mix(_ other: Color, _ t: Double) -> Color {
        let a = rgbaComponents, b = other.rgbaComponents
        return Color(
            .sRGB,
            red: a.r + (b.r - a.r) * t,
            green: a.g + (b.g - a.g) * t,
            blue: a.b + (b.b - a.b) * t,
            opacity: a.a + (b.a - a.a) * t
        )
    }
}
