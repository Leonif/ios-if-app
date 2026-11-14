//
//  BidiText.swift
//  IFApp
//

import Foundation

enum BidiText {
    static func isolate(_ text: String) -> String {
        "\u{2068}\(text)\u{2069}"
    }
}
