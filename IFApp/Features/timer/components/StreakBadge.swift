//
//  StreakBadge.swift
//  IFApp
//

import SwiftUI

struct StreakBadge: View {
    let display: StreakDisplay
    let theme: ThemeTokens
    let onTap: () -> Void

    private static let milestones = [3, 7, 14, 30, 60]

    private var days: Int { display.count }

    private var accessibilityLabel: String {
        switch display {
        case .alive(let days): return strings.History.entryA11y(days)
        case .justEnded(let days, _): return strings.History.entryA11yLastStreak(days)
        case .none: return strings.History.entryA11yNoStreak
        }
    }

    private func progress(_ days: Int) -> Double {
        guard let next = Self.milestones.first(where: { $0 > days }) else { return 1 }
        let previous = Self.milestones.last(where: { $0 <= days }) ?? 0
        return Double(days - previous) / Double(next - previous)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if days > 0 {
                    ZStack {
                        Circle()
                            .stroke(theme.ringTrack, lineWidth: 2.2)
                        Circle()
                            .trim(from: 0, to: max(0.02, progress(days)))
                            .stroke(display.hasEnded ? theme.faint : theme.accent,
                                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .padding(2)
                    .frame(width: 22, height: 22)
                    .environment(\.layoutDirection, .leftToRight)

                    Text(verbatim: String(days))
                        .font(.hanken(13.5, .bold))
                        .monospacedDigit()
                        .foregroundColor(display.hasEnded ? theme.mut : theme.ink)
                } else {
                    Image("history-arrow")
                        .renderingMode(.template)
                        .foregroundColor(theme.sec)
                        .frame(width: 17, height: 17)
                        .padding(.leading, 4)
                }
                Image(systemName: "chevron.forward")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(theme.mut)
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(theme.secBg)
                    .overlay(Capsule().stroke(theme.secLine, lineWidth: 1))
            )
            .frame(height: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("streak.badge")
        .accessibilityLabel(accessibilityLabel)
    }
}
