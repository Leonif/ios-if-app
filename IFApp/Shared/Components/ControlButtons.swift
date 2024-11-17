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
                Text("Старт")
                    .font(.headline)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(isRunning ? Color.gray.opacity(0.3) : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isRunning)
            
            HStack(spacing: 12) {
                Button(action: onReset) {
                    Text("Сброс")
                        .font(.headline)
                        .frame(width: 100, height: 48)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onStop) {
                    Text("Стоп")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(!isRunning ? Color.gray.opacity(0.3) : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}
