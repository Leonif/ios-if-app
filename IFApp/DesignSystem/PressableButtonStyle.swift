//
//  PressableButtonStyle.swift
//  IFApp
//
//  iOS replacement for the HTML hover affordance: depress on press only.
//  ~0.97 scale + slight dim, 0.13s ease-out.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.13), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
