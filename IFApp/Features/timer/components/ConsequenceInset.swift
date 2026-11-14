//
//  ConsequenceInset.swift
//  IFApp
//

import SwiftUI

struct ConsequenceInset: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let text: String
    let theme: ThemeTokens
    let identifier: String

    private static let messageDelay: TimeInterval = 0.42
    private static let messageRise: TimeInterval = 0.42

    @State private var messageShown = false

    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.hanken(14, .medium))
                .lineSpacing(14 * 0.35)
                .foregroundColor(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(messageShown ? 1 : 0)
                .offset(y: messageShown ? 0 : 28)
                .accessibilityIdentifier(identifier)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.surfaceQuiet))
        .onAppear {
            guard !reduceMotion else { messageShown = true; return }
            withAnimation(.timingCurve(0.22, 0.8, 0.3, 1, duration: Self.messageRise)
                            .delay(Self.messageDelay)) {
                messageShown = true
            }
        }
    }
}
