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
        HStack(spacing: 8) {
            Text(phase.displayString)
                .font(.system(size: 20))
            
            Image(systemName: phase.systemImageName)
                .font(.system(size: 18))
                .foregroundColor(phase.stageColor)
            
            Text(elapsedInPhase)
                .font(.system(size: 18, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
}
