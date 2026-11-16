//
//  TimerFlowView+RingAnchorKey.swift
//  IFApp
//

import SwiftUI

extension TimerFlowView {
    struct RingAnchorKey: PreferenceKey {
        static var defaultValue: Anchor<CGRect>?
        static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
            value = value ?? nextValue()
        }
    }
}
