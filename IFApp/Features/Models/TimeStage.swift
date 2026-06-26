//
//  Entities.swift
//  IFApp
//
//  Created by Leonid-user on 13.11.2024.
//

import Foundation
import SwiftUI

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
        case .anabolic: return 0
        case .catabolic: return 4
        case .fatBurning8: return 8
        case .fatBurning12: return 8
        case .fatBurning16: return 8
        case .fatBurning24: return 8
        case .fatBurning36: return 8
        }
    }
    
    var systemImageName: String {
        switch self {
        case .anabolic: return "wrench.fill"
        case .catabolic: return "bolt.fill"
        default: return "flame.fill"
        }
    }
    
    var stageColor: Color {
        switch self {
        case .anabolic: return .yellow
        case .catabolic: return .orange
        default: return .red
        }
    }
    
    var displayString: String {
        switch self {
        case .anabolic: return L10n.Phases.anabolic
        case .catabolic: return L10n.Phases.catabolic
        default: return L10n.Phases.fatBurning
        }
    }
        
    var description: String {
            switch self {
            case .anabolic:
                return L10n.Phases.Description.anabolic
            case .catabolic:
                return L10n.Phases.Description.catabolic
            default:
                return L10n.Phases.Description.fatBurning
            }
        }
        
        var extraDescription: String? {
            switch self {
            case .fatBurning12:
                return L10n.Phases.Extra.hours12
            case .fatBurning16:
                return L10n.Phases.Extra.hours16
            case .fatBurning24:
                return L10n.Phases.Extra.hours24
            case .fatBurning36:
                return L10n.Phases.Extra.hours36
            default:
                return nil
            }
        }
    
    static func determineStage(from timeInterval: TimeInterval) -> TimeStage {
        let hours = Int(timeInterval) / 3600
        switch hours {
        case 0..<4: return .anabolic
        case 4..<8: return .catabolic
        case 8..<12: return .fatBurning8
        case 12..<16: return .fatBurning12
        case 16..<24: return .fatBurning16
        case 24..<36: return .fatBurning24
        default: return .fatBurning36
        }
    }
}
