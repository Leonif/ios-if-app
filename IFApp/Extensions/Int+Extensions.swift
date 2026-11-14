//
//  Int+Extensions.swift
//  IFApp
//

import Foundation

extension Int {
    var minTimeInterval: TimeInterval {
        TimeInterval(self * 60)
    }
}
