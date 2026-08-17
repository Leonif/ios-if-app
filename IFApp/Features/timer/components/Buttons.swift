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
    var height: CGFloat = 52
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
                .frame(height: height)
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

/// The full-width actions of the consequence sheets, stacked one under the other.
///
/// Not `PrimaryButton` with a different number: three of its properties are wrong
/// here and each for its own reason.
///
/// - **No `minimumScaleFactor`.** A label naturally wider than ~153pt at the xxLarge
///   ceiling renders *below* base size under a floor of 0.7 — someone who turned text
///   up gets smaller type on the one control that matters, and no automated hunt for
///   truncation sees it because there is no truncation. The label wraps instead, and
///   the shape grows with it.
/// - **`minHeight`, not `height`.** Same reason: a box measured off the English
///   mock-up overflows in German, and the defect looks like overlap rather than a clip.
/// - **No drop shadow.** These sit on a sheet card, not over a scrolling screen; the
///   shadow that lifts the footer's primary off the timer only muddies the edge here.
struct SheetPrimaryButton: View {
    let title: String
    let theme: ThemeTokens
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hanken(16, .bold))
                .foregroundColor(theme.primaryButtonText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, labelInset)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 16).fill(theme.primaryButtonBg))
        }
        .buttonStyle(.pressable)
    }
}

/// The reversible action of the consequence sheets: `Keep this fast`, `Open that
/// fast`. Drawn on the quiet material rather than as a bordered secondary, which is
/// what keeps it from reading as a third option in a list of choices — it is the
/// named form of closing the sheet, the thing the scrim tap does, spelled out. Last
/// element, no chevron, full width.
struct QuietActionButton: View {
    let title: String
    let theme: ThemeTokens
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hanken(16, .bold))
                .foregroundColor(theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, labelInset)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.surfaceQuiet)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.surfaceQuietLine, lineWidth: 1))
                )
        }
        .buttonStyle(.pressable)
    }
}
