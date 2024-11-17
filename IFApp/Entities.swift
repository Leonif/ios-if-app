//
//  Entities.swift
//  IFApp
//
//  Created by Leonid-user on 13.11.2024.
//

import Foundation

enum TimeStage {
    case anabolic
    case catabolic
    case fatBurning8
    case fatBurning12
    case fatBurning16
    case fatBurning24
    case fatBurning36
    
    var startHour: Int {
        switch self {
        case .anabolic:
            return 0
        case .catabolic:
            return 4
        default:
            return 8
        }
    }
}

//#Preview {
//    TimerView()
//}
//

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
