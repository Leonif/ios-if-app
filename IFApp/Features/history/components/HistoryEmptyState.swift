//
//  HistoryEmptyState.swift
//  IFApp
//
//  Nothing recorded yet. Ghost rings rather than an icon — the ring is the app's
//  one shape, and an empty one says "this is waiting to be filled" without a single
//  zero on screen. The copy promises what will be kept; it never scolds.
//

import SwiftUI

/// What the one button offers. There is always exactly one, and the state never
/// appears without it: an empty screen whose only interactive thing is a bare chevron
/// is the hole this was found in, and hiding a dead CTA would have deepened it rather
/// than filled it.
///
/// The copy above does not vary with this — "no fast has finished yet" is the reason
/// the screen is empty either way. Only the way out changes.
enum HistoryEmptyAction {
    /// Nothing in flight: the invitation to begin one.
    case startFast
    /// A fast is already running, and `StartFastThunk` refuses a second — so the
    /// honest action is the way back to the one going. The label names where it leads
    /// rather than saying "Back": the chevron already says that.
    case backToFast

    var title: String {
        switch self {
        case .startFast: return strings.History.emptyCta
        case .backToFast: return strings.History.emptyBackToFast
        }
    }

    /// `history.startFast` is unchanged on purpose — the existing suite addresses the
    /// invitation by that name, and renaming it is not part of adding a second case.
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

            // Hugs its label rather than spanning the screen like the footer's
            // primary button — an invitation, not the screen's main action.
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
