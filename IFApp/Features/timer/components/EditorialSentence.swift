//
//  EditorialSentence.swift
//  IFApp
//

import SwiftUI

struct EditorialSentence: View {
    let text: String
    let theme: ThemeTokens

    var body: some View {
        Text(text)
            .font(.hanken(16.5, .regular))
            .lineSpacing(16.5 * 0.5)
            .multilineTextAlignment(.center)
            .foregroundColor(theme.sec)
            .frame(maxWidth: 316)
            .fixedSize(horizontal: false, vertical: true)
    }
}
