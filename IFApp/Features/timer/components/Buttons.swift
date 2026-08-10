//
//  Buttons.swift
//  IFApp
//
//  Shared primary (green) and secondary button shapes used across footer + sheets.
//
//  Both keep `labelInset` of horizontal breathing room inside the shape: an English
//  label ("Reset", "Continue fasting") never comes near the corner radius, but its
//  German and Ukrainian counterparts ("Zurücksetzen", "Продовжити піст") are half
//  again as long and would otherwise sit flush against the rounded edge.
//

import SwiftUI

/// Horizontal breathing room between a button's label and its rounded edge.
private let labelInset: CGFloat = 14

struct PrimaryButton: View {
    let title: String
    let theme: ThemeTokens
    var cornerRadius: CGFloat = 15
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hanken(17, .bold))
                .foregroundColor(theme.primaryButtonText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, labelInset)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: cornerRadius).fill(theme.primaryButtonBg))
                .shadow(color: theme.buttonShadow, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.pressable)
    }
}

struct SecondaryButton: View {
    let title: String
    let theme: ThemeTokens
    var cornerRadius: CGFloat = 15
    /// Paired with a primary button, the secondary sizes to its own label rather than
    /// taking half the row: it starts at `minWidth` and widens for a longer locale,
    /// leaving the rest to the primary. Left nil, the button fills its container
    /// (sheets, where it is the only button in the row).
    var minWidth: CGFloat? = nil
    let action: () -> Void

    /// Cap on the content-sized width, so a very long secondary label cannot crowd
    /// the primary action out of the row — past this the label scales down instead.
    private static let maxContentWidth: CGFloat = 152

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hanken(17, .bold))
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, labelInset)
                .frame(minWidth: minWidth,
                       maxWidth: minWidth.map { _ in Self.maxContentWidth } ?? .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.secBg)
                        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(theme.secLine, lineWidth: 1))
                )
        }
        .buttonStyle(.pressable)
        // Content-sized only when a floor is given: the nil proposal makes the frame
        // above resolve to the label's own width inside [minWidth, maxContentWidth].
        .fixedSize(horizontal: minWidth != nil, vertical: false)
    }
}
