//
//  View+Tracking.swift
//  IFApp
//

import SwiftUI

private struct OverlineTracking: ViewModifier {
    let value: CGFloat
    @Environment(\.layoutDirection) private var layoutDirection

    private var suppressed: Bool {
        layoutDirection == .rightToLeft || Locale.current.language.languageCode?.identifier == "ko"
    }

    func body(content: Content) -> some View {
        content.tracking(suppressed ? 0 : value)
    }
}

private struct DisplayTracking: ViewModifier {
    let value: CGFloat
    @Environment(\.layoutDirection) private var layoutDirection

    private var suppressed: Bool {
        layoutDirection == .rightToLeft || Locale.current.language.languageCode?.identifier == "ko"
    }

    func body(content: Content) -> some View {
        content.tracking(suppressed ? 0 : value)
    }
}

extension View {
    func overlineTracking(_ value: CGFloat) -> some View {
        modifier(OverlineTracking(value: value))
    }

    func displayTracking(_ size: CGFloat, _ em: CGFloat) -> some View {
        modifier(DisplayTracking(value: size * em))
    }
}
