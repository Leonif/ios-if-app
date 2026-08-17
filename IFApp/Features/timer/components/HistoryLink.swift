//
//  HistoryLink.swift
//  IFApp
//
//  The text link into the history: "Saved to your history" once a fast is done,
//  "Last fast · 16h 24m" while the eating window is open. The chevron is the whole
//  navigation affordance.
//
//  It lives outside the footer file because it is no longer only a footer element:
//  on the result screen the row was moved out of the pinned zone into the scrolling
//  middle, where a zero-consequence navigation cannot compete with the one reversible
//  action on the card.
//

import SwiftUI

struct HistoryLink: View {
    let title: String
    let theme: ThemeTokens
    let identifier: String
    /// Defaults to the brand green the footer rows have always used. The row under
    /// the phase scale takes `mut` instead: down there it is a signpost, not one of
    /// the choices being weighed.
    var tint: Color? = nil
    /// A floor for the tappable row. The footer rows keep their glyph-sized target;
    /// the row in the scrolling middle is a standalone control and takes the HIG 44.
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
            // The floor sits on the label with a content shape behind it, so the whole
            // row is tappable rather than only the glyph box. Where no floor is asked
            // for, the target stays the glyphs: in the footer that was deliberate —
            // invisible hot area under a neighbouring control is how a tap a few points
            // low on one row landed on the other.
            .frame(minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier(identifier)
    }
}
