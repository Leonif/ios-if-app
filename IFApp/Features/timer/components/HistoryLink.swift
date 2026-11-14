//
//  HistoryLink.swift
//  IFApp
//

import SwiftUI

struct HistoryLink: View {
    let title: String
    let theme: ThemeTokens
    let identifier: String
    var tint: Color? = nil
    var minHeight: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 9, weight: .semibold))
            }
            .font(.hanken(13.5, .semibold))
            .foregroundColor(tint ?? theme.deep)
            .frame(minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier(identifier)
    }
}
