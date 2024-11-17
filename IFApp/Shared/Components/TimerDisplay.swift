//
//  TimerDisplay.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct TimerDisplay: View {
    let timeString: String
    let dateString: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dateString)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Text(timeString)
                .font(.system(size: 38, weight: .regular, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
                .padding(.vertical, 8)
        }
    }
}
