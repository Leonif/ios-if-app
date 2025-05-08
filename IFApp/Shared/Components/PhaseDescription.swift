//
//  PhaseDescription.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct LineItem: Identifiable {
    let id = UUID()
    let text: String
}

struct PhaseDescription: View {
    let description: String
    let extraInfo: String?
    
    @State private var isCollapsed = false
    @State private var timerStarted = false
    
    private var lines: [LineItem] {
        description.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { LineItem(text: $0) }
    }
    
    var body: some View {
        Group {
            if isCollapsed {
                Button(action: {
                    withAnimation(.spring()) {
                        isCollapsed = false
                        timerStarted = false // сбросим таймер, чтобы не сворачивалось сразу снова
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text(L10n.Phases.Description.showDescription)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.08))
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            } else {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(lines) { line in
                            Text(line.text)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.08))
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    )
                    
                    if let extraInfo = extraInfo {
                        HStack(spacing: 12) {
                            Text("💡")
                                .font(.title2)
                            
                            Text(extraInfo)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.06))
                                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.2), value: extraInfo)
                .onAppear {
                    if !timerStarted {
                        timerStarted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            withAnimation(.spring()) {
                                isCollapsed = true
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: description) { _ in
            withAnimation(.spring()) {
                isCollapsed = false
                timerStarted = false
            }
        }
    }
}
