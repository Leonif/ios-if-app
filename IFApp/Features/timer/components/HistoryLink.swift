//
//  HistoryLink.swift
//  IFApp
//

import SwiftUI

struct HistoryLink: View {
    let title: String
    let theme: ThemeTokens
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 9, weight: .semibold))
            }
            .font(.hanken(13.5, .semibold))
            .foregroundColor(theme.deep)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier(identifier)
    }
}
