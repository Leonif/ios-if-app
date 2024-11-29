//
//  CircularProgressView.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let timeString: String
    let startTimeString: String?
    let currentStage: TimeStage
    
    private var stageGradient: LinearGradient {
        switch currentStage {
        case .anabolic:
            return LinearGradient(
                gradient: Gradient(colors: [.yellow, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .catabolic:
            return LinearGradient(
                gradient: Gradient(colors: [.orange, .red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [.red, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var stageColor: Color {
        switch currentStage {
        case .anabolic: return .yellow
        case .catabolic: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            
            // Фоновый круг
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.1)
                .foregroundColor(stageColor)
            
            // Фазовые метки
            ForEach(0..<4) { i in
                Rectangle()
                    .frame(width: 2, height: 10)
                    .offset(y: -95)
                    .rotationEffect(.degrees(Double(i) * 90))
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Прогресс
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(stageGradient, style: StrokeStyle(
                    lineWidth: 12,
                    lineCap: .round
                ))
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
            
            // Текст в центре
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                if let startTimeString {
                    Text(startTimeString)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            
            // Текущая фаза (маленькая точка на круге)
            PulsingDot(color: stageColor)
                .offset(y: -100)
                .rotationEffect(.degrees(progress * 360))

            // Фазовые подписи (опционально)
            ForEach(0..<4) { i in
                Text(phaseLabel(for: i))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .offset(y: -115)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: 200, height: 200)
        .padding()
    }
    
    private func phaseLabel(for index: Int) -> String {
        switch index {
        case 0: return "0h"
        case 1: return "6h"
        case 2: return "12h"
        case 3: return "18h"
        default: return ""
        }
    }
}


struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 15, height: 15)
            .padding(2)
            .background(
//                RoundedRectangle(cornerRadius: 3)
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 1)
            )
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}
