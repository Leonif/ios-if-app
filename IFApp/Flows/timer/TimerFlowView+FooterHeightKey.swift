//
//  TimerFlowView+FooterHeightKey.swift
//  IFApp
//

import SwiftUI

extension TimerFlowView {
    struct FooterHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
