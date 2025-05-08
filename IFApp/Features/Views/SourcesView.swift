//
//  SourcesView.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 08.05.2025.
//

import SwiftUI
import UIKit

struct SourcesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Top bar with dismiss button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)
                
                // Disclaimer section
                VStack(spacing: 12) {
                    Text(L10n.Sources.disclaimerTitle)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(L10n.Cautions.disclaimer)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                // Sources section
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.Sources.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    SourceLinkView(
                        number: 1,
                        title: L10n.Sources.source1Title,
                        url: "https://pubmed.ncbi.nlm.nih.gov/22248338/"
                    )
                    
                    SourceLinkView(
                        number: 2,
                        title: L10n.Sources.source2Title,
                        url: "https://pubmed.ncbi.nlm.nih.gov/28459931/"
                    )
                    
                    SourceLinkView(
                        number: 3,
                        title: L10n.Sources.source3Title,
                        url: "https://www.nature.com/articles/s41467-020-14384-z"
                    )
                    
                    SourceLinkView(
                        number: 4,
                        title: L10n.Sources.source4Title,
                        url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/#:~:text=In%20summary%2C%20intermittent%20fasting%20has,levels%20of%20leptin%20and%20adiponectin."
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct SourceLinkView: View {
    let number: Int
    let title: String
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("\(number).")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Button(action: {
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(L10n.Sources.buttonViewStudy)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SourcesView()
}
