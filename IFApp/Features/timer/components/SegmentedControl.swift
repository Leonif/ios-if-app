//
//  SegmentedControl.swift
//  IFApp
//
//  Shared segmented control for the plan editor and the quick last-meal chips.
//

import SwiftUI

struct SegmentedControl: View {
    let options: [String]
    let selectedIndex: Int
    let theme: ThemeTokens
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, title in
                let isSelected = idx == selectedIndex
                Button { onSelect(idx) } label: {
                    Text(title)
                        .font(.hanken(13.5, .semibold))
                        .foregroundColor(isSelected ? theme.deep : theme.mut)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(isSelected ? theme.segActive : .clear)
                                .shadow(color: isSelected ? theme.segActiveShadow : .clear,
                                        radius: 6, x: 0, y: 2)
                        )
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.segTrack))
    }
}
