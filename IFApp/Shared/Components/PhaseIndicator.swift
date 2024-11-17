//
//  PhaseIndicator.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct PhaseIndicator: View {
    let phase: TimeStage
    let elapsedInPhase: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(phase.displayString)
                .font(.title3.weight(.medium))
            
            Image(systemName: phase.systemImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(phase.stageColor)
                .frame(width: 24, height: 24)
            
            if phase.startHour != 0 {
                Text(elapsedInPhase)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
