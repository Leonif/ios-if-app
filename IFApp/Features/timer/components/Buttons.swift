//
//  Buttons.swift
//  IFApp
//

import SwiftUI

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
                .frame(minHeight: height)
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
    var minWidth: CGFloat? = nil
    let action: () -> Void

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
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.secBg)
                        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(theme.secLine, lineWidth: 1))
                )
        }
        .buttonStyle(.pressable)
        .fixedSize(horizontal: minWidth != nil, vertical: false)
    }
}

struct TertiaryTextButton: View {
    let title: String
    let theme: ThemeTokens
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hanken(15, .semibold))
                .foregroundColor(theme.mut)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.94)
                .padding(.horizontal, labelInset)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}

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
