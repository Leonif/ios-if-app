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
    
    private var lines: [LineItem] {
        description.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { LineItem(text: $0) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines) { line in
                    Text(line.text)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(16)
            
            // Дополнительная информация о длительных фазах
            if let extraInfo = extraInfo {
                HStack(spacing: 8) {
                    Text("💡")
                        .font(.title3)
                    
                    Text(extraInfo)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
}
