//
//  TimeControlButton.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct TimeControlButton: View {
    let action: () -> Void
    let direction: String // "left" или "right"
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "chevron.\(direction)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}
