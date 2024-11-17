//
//  PhaseDescription.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI

struct PhaseDescription: View {
    let description: String
    let extraInfo: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
            
            if let extraInfo = extraInfo {
                HStack(alignment: .top, spacing: 8) {
                    Text("💡")
                        .font(.title3)
                    
                    Text(extraInfo)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
}
