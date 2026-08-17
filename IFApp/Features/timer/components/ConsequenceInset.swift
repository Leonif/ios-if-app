//
//  ConsequenceInset.swift
//  IFApp
//
//  The consequence message — the app's third register, next to prose and buttons.
//  The app could say "this matters" (a text level) and "this is an action" (a
//  button); it could not say "this will cost you". One genre, one component: the
//  end-of-fast sheet (mode A, in a card with no scroll) and the result-screen footer
//  (mode C, pinned outside the scroll) draw the same inset, so the two surfaces
//  cannot drift into two dialects of the same sentence.
//
//  Rules that are not stylistic:
//
//  - **Never tappable, and it must never look it.** No press state, no chevron, and a
//    radius small enough that it cannot be mistaken for a card.
//  - **`minHeight`, never a fixed height.** The measured inset is 66pt at the default
//    type size and 76pt at the xxLarge ceiling (worst case Japanese, whose line box
//    is 25.94pt against Hanken's 22.53pt). A box measured off the English mock-up
//    overflows in German, and that defect looks like overlap rather than a clip.
//  - **No `minimumScaleFactor`.** At the ceiling a label this wide would render below
//    base size under a 0.7 floor: text turned up, type turned down. It wraps instead.
//

import SwiftUI

struct ConsequenceInset: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let text: String
    let theme: ThemeTokens
    let identifier: String

    /// The message rises after the surface it sits in has settled — never over a
    /// transition. Both numbers come from 1.5.0's accepted motion and are two values
    /// on purpose: the wait and the travel may be retuned apart.
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
                // Only the message moves. The fill it sits in is drawn with the
                // surface and never animates.
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
            // The wait is a property of the curve, not a scheduled job: `.delay` keeps
            // the pause inside the animation the view already declares, so there is no
            // timer to outlive the surface if it closes during those 0.42s.
            withAnimation(.timingCurve(0.22, 0.8, 0.3, 1, duration: Self.messageRise)
                            .delay(Self.messageDelay)) {
                messageShown = true
            }
        }
    }
}
