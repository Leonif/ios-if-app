//
//  Buttons.swift
//  IFApp
//
//  Shared primary (green) and secondary button shapes used across footer + sheets.
//

import SwiftUI

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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hanken(17, .bold))
                .foregroundColor(theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.secBg)
                        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(theme.secLine, lineWidth: 1))
                )
        }
        .buttonStyle(.pressable)
    }
}
