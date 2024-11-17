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
        case .fatBurning12: return 12
        case .fatBurning16: return 16
        case .fatBurning24: return 24
        case .fatBurning36: return 36
        }
    }
    
    var displayString: String {
        switch self {
        case .anabolic: return "Anabolic"
        case .catabolic: return "Catabolic"
        default: return "Fat Burning"
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
    
    var description: String {
        switch self {
        case .anabolic:
            return """
                🍽️ Период активного пищеварения и усвоения питательных веществ
                🩸 В крови повышен уровень глюкозы и инсулина
                ⚡ Организм запасает энергию в мышцах и печени в виде гликогена
                🏋️ Излишки углеводов преобразуются в жиры
                🔄 Активно идут процессы восстановления и роста тканей
                💪 Это оптимальное время для тренировок на массу
                """
        case .catabolic:
            return """
                📉 Уровень глюкозы и инсулина снижается
                🔋 Организм начинает использовать запасы гликогена
                ⚖️ Активизируются процессы расщепления
                🧪 Начинается выработка глюкагона - гормона, способствующего расщеплению гликогена
                🔄 Организм постепенно переходит на использование жировых запасов
                🏃 В этой фазе хорошо проводить кардио тренировки
                """
        default:
            return """
                📪 Запасы гликогена истощаются
                🔥 Организм переключается на использование жировых запасов как основного источника энергии
                ⚗️ Активно вырабатываются кетоновые тела
                📉 Снижается уровень инсулина до минимума
                🧹 Активируются процессы аутофагии (очищение клеток)
                📈 Увеличивается выработка гормона роста
                ✨ Улучшается чувствительность к инсулину
                🔥 Происходит активное жиросжигание
                💪 Это оптимальное время для жиросжигающих тренировок
                """
        }
    }
    
    var extraDescription: String? {
        switch self {
        case .fatBurning12:
            return "12 часов: полное истощение запасов гликогена"
        case .fatBurning16:
            return "16-18 часов: максимальное жиросжигание"
        case .fatBurning24:
            return "24 часа: значительное усиление аутофагии"
        case .fatBurning36:
            return "36-48 часов: обновление иммунной системы"
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
