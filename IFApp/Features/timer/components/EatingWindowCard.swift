//
//  EatingWindowCard.swift
//  IFApp
//

import SwiftUI

private func hourMinuteSecond(_ remaining: TimeInterval) -> String {
    let total = max(0, Int(remaining))
    return String(format: "%d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
}

struct EatingWindowCard: View {
    let remaining: TimeInterval
    let closesAt: String
    let theme: ThemeTokens

    var body: some View {
        WindowCard(overline: strings.Timer.eatingWindow,
                   overlineMarked: true,
                   value: hourMinuteSecond(remaining),
                   theme: theme) {
            Text(strings.Timer.closesAt(closesAt))
                .font(.hanken(16, .semibold))
                .foregroundColor(theme.ink)
        }
    }
}

struct EatingOverCard: View {
    let sinceClose: TimeInterval
    let theme: ThemeTokens

    var body: some View {
        WindowCard(overline: strings.Timer.windowClosed,
                   value: hourMinuteSecond(sinceClose),
                   theme: theme) {
            Text(strings.Timer.fastingSoFar)
                .font(.hanken(14, .regular))
                .foregroundColor(theme.mut)
        }
    }
}

private struct WindowCard<Caption: View>: View {
    let overline: String
    var overlineMarked = false
    let value: String
    let theme: ThemeTokens
    @ViewBuilder let caption: Caption
    @State private var haloDimmed = false

    private var overlineText: Text {
        let label = Text(overline).foregroundStyle(theme.deep)
        guard overlineMarked else { return label }
        return Text(Image(systemName: "circle.fill")).foregroundStyle(theme.accent)
            + Text(verbatim: " ")
            + label
    }

    var body: some View {
        VStack(spacing: 10) {
            overlineText
                .font(.hanken(12, .semibold))
                .overlineTracking(1.9)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(width: 160, height: 30)
                .accessibilityLabel(Text(overline))

            Text(value)
                .font(.bricolage(42))
                .monospacedDigit()
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            caption
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(width: 176, height: 40)
        }
        .frame(width: 232, height: 232)
        .background(
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(theme.isDark ? 0.30 : 0.22))
                    .padding(-6)
                    .blur(radius: 26)
                    .scaleEffect(haloDimmed ? 0.96 : 1.07)
                    .opacity(haloDimmed ? 0.55 : 1)
                Circle()
                    .fill(theme.surface)
                    .overlay(Circle().stroke(theme.surfaceLine, lineWidth: 1))
                    .shadow(color: theme.cardShadow, radius: 24, x: 0, y: 10)
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                haloDimmed = true
            }
        }
    }
}
