//
//  TimeInterval+Extensions.swift
//  IFApp
//

import Foundation

extension TimeInterval {
    var hours: Int {
        Int(self) / 3600
    }
    var minutes: Int {
        Int(self) / 60 % 60
    }
    
    var seconds: Int {
        Int(self) % 60
    }
    
    var timeString: String {
        String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
