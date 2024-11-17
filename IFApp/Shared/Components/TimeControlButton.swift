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
            Image(systemName: "chevron.\(direction).circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}
