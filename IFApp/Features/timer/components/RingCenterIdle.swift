//
//  RingCenterIdle.swift
//  IFApp
//

import SwiftUI

struct RingCenterIdle: View {
    let theme: ThemeTokens
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 26))
                Text(strings.Timer.start)
                    .font(.hanken(17, .bold))
            }
            .foregroundColor(theme.primaryButtonText)
            .frame(width: 154, height: 154)
            .background(Circle().fill(theme.primaryButtonBg))
            .shadow(color: theme.buttonShadow, radius: 18, x: 0, y: 16)
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier("timer.start")
    }
}
