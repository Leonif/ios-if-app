//
//  View+ContentWidth.swift
//  IFApp
//

import SwiftUI

extension View {
    func contentWidth() -> some View {
        frame(maxWidth: ContentLayout.maxWidth)
            .frame(maxWidth: .infinity)
    }
}
