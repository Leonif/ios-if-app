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
        VStack(spacing: 8) {
            Text(dateString)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text(timeString)
                .font(.system(size: 54, weight: .light, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}
