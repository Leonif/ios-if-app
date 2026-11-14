//
//  Font+Typography.swift
//  IFApp
//

import SwiftUI

extension Font {
    static func bricolage(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("Bricolage Grotesque", size: size).weight(weight)
    }

    static func hanken(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Hanken Grotesk", size: size).weight(weight)
    }
}
