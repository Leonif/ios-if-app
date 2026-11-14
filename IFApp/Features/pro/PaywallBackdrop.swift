//
//  PaywallBackdrop.swift
//  IFApp
//

import SwiftUI

struct PaywallBackdrop: View {
    let phaseColor: Color
    let theme: ThemeTokens

    var body: some View {
        ZStack {
            theme.backgroundBase
            GeometryReader { geo in
                let radius = geo.size.width * 1.3
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: phaseColor.opacity(theme.isDark ? 0.22 : 0.16), location: 0),
                        .init(color: phaseColor.opacity(0), location: 0.72),
                        .init(color: phaseColor.opacity(0), location: 1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
                .frame(width: radius * 2, height: radius * 2)
                .scaleEffect(x: 1, y: geo.size.height * 0.55 / radius)
                .position(x: geo.size.width / 2, y: 0)
            }
        }
        .ignoresSafeArea()
    }
}
