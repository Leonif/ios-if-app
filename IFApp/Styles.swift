//
//  BorderedButtonStyle.swift
//  IFApp
//
//  Created by Leonid-user on 13.11.2024.
//
import SwiftUI

struct BorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

