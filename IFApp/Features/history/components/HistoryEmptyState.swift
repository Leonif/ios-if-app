//
//  HistoryEmptyState.swift
//  IFApp
//

import SwiftUI

enum HistoryEmptyAction {
    case startFast
    case backToFast

    var title: String {
        switch self {
        case .startFast: return strings.History.emptyCta
        case .backToFast: return strings.History.emptyBackToFast
        }
    }

    var identifier: String {
        switch self {
        case .startFast: return "history.startFast"
        case .backToFast: return "history.empty.backToFast"
        }
    }
}

struct HistoryEmptyState: View {
    let theme: ThemeTokens
    let action: HistoryEmptyAction
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ring(148)
                ring(104)
                ring(62)
                Circle()
                    .fill(theme.accent)
                    .frame(width: 8, height: 8)
                    .offset(y: -74)
            }
            .frame(width: 148, height: 148)
            .accessibilityHidden(true)

            Text(strings.History.emptyTitle)
                .font(.bricolage(25))
                .foregroundColor(theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 34)

            Text(strings.History.emptyBody)
                .font(.hanken(15.5))
                .lineSpacing(15.5 * 0.55)
                .foregroundColor(theme.sec)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 294)
                .padding(.top, 12)

            Button(action: onTap) {
                Text(action.title)
                    .font(.hanken(15, .bold))
                    .foregroundColor(theme.primaryButtonText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .background(RoundedRectangle(cornerRadius: 15).fill(theme.primaryButtonBg))
                    .shadow(color: theme.buttonShadow, radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.pressable)
            .padding(.top, 26)
            .accessibilityIdentifier(action.identifier)
        }
        .frame(maxWidth: .infinity)
    }

    private func ring(_ diameter: CGFloat) -> some View {
        Circle()
            .stroke(theme.historyGhostLine, lineWidth: 1)
            .frame(width: diameter, height: diameter)
    }
}
