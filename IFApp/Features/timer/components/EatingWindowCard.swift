//
//  EatingWindowCard.swift
//  IFApp
//
//  The eating-window center: a light countdown to when the next fast starts. No ring,
//  no phases — the window is a calm pause between fasts. Overline + H:MM:SS + caption.
//  EatingOverCard reuses the same card for the window-closed count-up.
//

import SwiftUI

/// "7:59:59" from a remaining interval (H:MM:SS).
private func hourMinuteSecond(_ remaining: TimeInterval) -> String {
    let total = max(0, Int(remaining))
    return String(format: "%d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
}

struct EatingWindowCard: View {
    let remaining: TimeInterval     // seconds until the window closes / fast starts
    let closesAt: String            // "8:00 PM" — the hour eating has to end by
    let theme: ThemeTokens

    var body: some View {
        // The countdown answers "how long left"; the caption answers "until when",
        // which is the question people actually plan a meal around.
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

/// The window-closed center: the same calm card, but counting UP since the window
/// closed — that time already belongs to the next fast once the user continues.
struct EatingOverCard: View {
    let sinceClose: TimeInterval    // seconds since the window closed
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

/// Shared circular card: overline + H:MM:SS + caption over the pulsing halo.
private struct WindowCard<Caption: View>: View {
    let overline: String
    var overlineMarked = false
    let value: String
    let theme: ThemeTokens
    @ViewBuilder let caption: Caption
    @State private var haloDimmed = false

    /// The live dot is part of the overline, not a sibling of it. As inline content of
    /// the label it gets three things for free that a neighbouring view cannot: it
    /// mirrors to the right of the text in Arabic (the run order is the text's, so no
    /// left/right rule is written anywhere), it stays on the first line box when the
    /// label wraps to two lines instead of centring itself against the whole block, and
    /// it is sized by the label's font — so it grows with Dynamic Type instead of
    /// shrinking to a speck at the accessibility sizes.
    private var overlineText: Text {
        let label = Text(overline).foregroundStyle(theme.deep)
        guard overlineMarked else { return label }
        // `verbatim`: a plain `Text(" ")` is a localisable literal, and it becomes a
        // catalog key made of one space with ten empty locales that nobody can ever
        // fill or retire.
        return Text(Image(systemName: "circle.fill")).foregroundStyle(theme.accent)
            + Text(verbatim: " ")
            + label
    }

    var body: some View {
        VStack(spacing: 10) {
            // Same boundary problem as the caption, one line higher: "WINDOW CLOSED"
            // is "FENSTER GESCHLOSSEN" in German, and at a large content size it runs
            // straight out of the circle. It gets the chord width at its own height —
            // narrower than the caption's, because it sits nearer the top of the circle
            // — and wraps inside that, in a fixed two-line slot so the countdown and
            // the caption stay put whether the overline takes one line or two.
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

            // The circle is a hard boundary, and the caption is the one line that
            // varies with the locale ("Fasting so far" is three words in English and
            // four in Ukrainian). It gets the chord width at its own height minus a
            // margin, and wraps inside that instead of growing past the edge.
            //
            // The slot is a fixed two-line height so the countdown sits in the same
            // place whether the caption takes one line or two — the card must not
            // recompose itself from locale to locale.
            caption
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(width: 176, height: 40)
        }
        .frame(width: 232, height: 232)
        .background(
            ZStack {
                // Soft accent halo around the card, wider and dimmer than the drop shadow.
                // Pulses slowly like a heartbeat while the window is open.
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
