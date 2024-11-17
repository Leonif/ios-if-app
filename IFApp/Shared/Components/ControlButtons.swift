//
//  ControlButtons.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct ControlButtons: View {
    let isRunning: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onStart) {
                Text(L10n.Timer.start)
                    .font(.system(size: 20, weight: .medium))
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(isRunning ? Color.gray.opacity(0.3) : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isRunning)
            
            HStack(spacing: 12) {
                Button(action: onReset) {
                    Text(L10n.Timer.reset)
                        .font(.system(size: 20, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onStop) {
                    Text(L10n.Timer.stop)
                        .font(.system(size: 20, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}
