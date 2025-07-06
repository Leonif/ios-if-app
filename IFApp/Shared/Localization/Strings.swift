//
//  Strings.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

// Shared/Localization/Strings.swift
import Foundation

enum L10n {
    enum Timer {
        static let start = NSLocalizedString("timer.button.start",
            value: "Старт",
            comment: "Start timer button")
        
        static let stop = NSLocalizedString("timer.button.stop",
            value: "Стоп",
            comment: "Stop timer button")
        
        static let reset = NSLocalizedString("timer.button.reset",
            value: "Сброс",
            comment: "Reset timer button")
    }
    
    enum Phases {
        static let anabolic = NSLocalizedString("phase.anabolic",
            value: "Anabolic",
            comment: "Anabolic phase name")
            
        static let catabolic = NSLocalizedString("phase.catabolic",
            value: "Catabolic",
            comment: "Catabolic phase name")
            
        static let fatBurning = NSLocalizedString("phase.fatBurning",
            value: "Fat Burning",
            comment: "Fat burning phase name")
        
        enum Description {
            static let anabolic = NSLocalizedString("phase.description.anabolic",
                value: """
                🍽️ Период активного пищеварения и усвоения питательных веществ
                🩸 В крови повышен уровень глюкозы и инсулина
                ⚡ Организм запасает энергию в мышцах и печени в виде гликогена
                🏋️ Излишки углеводов преобразуются в жиры
                🔄 Активно идут процессы восстановления и роста тканей
                💪 Это оптимальное время для тренировок на массу
                """,
                comment: "Anabolic phase description")
                
            static let catabolic = NSLocalizedString("phase.description.catabolic",
                value: """
                📉 Уровень глюкозы и инсулина снижается
                🔋 Организм начинает использовать запасы гликогена
                ⚖️ Активизируются процессы расщепления
                🧪 Начинается выработка глюкагона - гормона, способствующего расщеплению гликогена
                🔄 Организм постепенно переходит на использование жировых запасов
                🏃 В этой фазе хорошо проводить кардио тренировки
                """,
                comment: "Catabolic phase description")
                
            static let fatBurning = NSLocalizedString("phase.description.fatBurning",
                value: """
                📪 Запасы гликогена истощаются
                🔥 Организм переключается на использование жировых запасов как основного источника энергии
                ⚗️ Активно вырабатываются кетоновые тела
                📉 Снижается уровень инсулина до минимума
                🧹 Активируются процессы аутофагии (очищение клеток)
                📈 Увеличивается выработка гормона роста
                ✨ Улучшается чувствительность к инсулину
                🔥 Происходит активное жиросжигание
                💪 Это оптимальное время для жиросжигающих тренировок
                """,
                comment: "Fat burning phase description")
                
            static let showDescription = NSLocalizedString("phase.description.show",
                value: "Показать описание",
                comment: "Button text to show phase description")
        }
        
        enum Extra {
            static let hours12 = NSLocalizedString("phase.extra.12hours",
                value: "12 часов: полное истощение запасов гликогена",
                comment: "12 hours milestone description")
                
            static let hours16 = NSLocalizedString("phase.extra.16hours",
                value: "16-18 часов: максимальное жиросжигание",
                comment: "16-18 hours milestone description")
                
            static let hours24 = NSLocalizedString("phase.extra.24hours",
                value: "24 часа: значительное усиление аутофагии",
                comment: "24 hours milestone description")
                
            static let hours36 = NSLocalizedString("phase.extra.36hours",
                value: "36-48 часов: обновление иммунной системы",
                comment: "36-48 hours milestone description")
        }
        
        
    }
    enum Cautions {
        static let disclaimer = NSLocalizedString("disclaimer",
            value: "Відмова від відповідальності: Цей додаток не надає медичних консультацій. Будь ласка, проконсультуйтеся з лікарем, перш ніж приймати будь-які рішення, пов'язані зі здоров'ям.",
            comment: "Відмова від відповідальності: Цей додаток не надає медичних консультацій. Будь ласка, проконсультуйтеся з лікарем, перш ніж приймати будь-які рішення, пов'язані зі здоров'ям.")
    }
    
    enum Notification {
        static let reminderTitle = NSLocalizedString("notification.reminder.title",
            value: "⏰ Напоминание",
            comment: "Title for daily notification")

        static let reminderBody = NSLocalizedString("notification.reminder.body",
            value: "Проверь свою фазу голодания!",
            comment: "Body text for daily notification")

        static let eveningTitle = NSLocalizedString("notification.evening.title",
            value: "🌅 Вечернее напоминание",
            comment: "Title for evening notification")

        static let eveningBody = NSLocalizedString("notification.evening.body",
            value: "Время проверить прогресс голодания!",
            comment: "Body text for evening notification")

        static let errorScheduling = NSLocalizedString("notification.error.scheduling",
            value: "Ошибка добавления уведомления",
            comment: "Error message when scheduling fails")

        static let scheduledMessage = NSLocalizedString("notification.scheduled",
            value: "Ежедневное уведомление запланировано на 12:00",
            comment: "Success message for scheduled daily notification")

        static let eveningScheduledMessage = NSLocalizedString("notification.evening.scheduled",
            value: "Вечернее уведомление запланировано на 17:00",
            comment: "Success message for scheduled evening notification")

        static let sentMessage = NSLocalizedString("notification.sent",
            value: "Уведомление отправлено",
            comment: "Message after sending immediate notification")

        static let allCancelled = NSLocalizedString("notification.cancelled",
            value: "Все уведомления отменены.",
            comment: "Message after cancelling all notifications")
        
        static func phaseTitle(_ phaseName: String) -> String {
            String(format: NSLocalizedString("notification.phase.title",
                value: "Фаза: %@",
                comment: "Notification title with current fasting phase"), phaseName)
        }
    }
    
    enum Sources {
        static let title = NSLocalizedString("sources.title",
            value: "Scientific Sources",
            comment: "Title for the sources screen")
            
        static let disclaimerTitle = NSLocalizedString("sources.disclaimer.title",
            value: "Disclaimer",
            comment: "Title for the disclaimer section")
            
        static let buttonViewStudy = NSLocalizedString("sources.button.viewStudy",
            value: "View Study",
            comment: "Button text to view the study")
            
        static let source1Title = NSLocalizedString("sources.source1.title",
            value: "Glycogen and its metabolism: some new developments and old themes",
            comment: "Title of the first scientific source")
            
        static let source2Title = NSLocalizedString("sources.source2.title",
            value: "Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial",
            comment: "Title of the second scientific source")
            
        static let source3Title = NSLocalizedString("sources.source3.title",
            value: "Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase",
            comment: "Title of the third scientific source")
            
        static let source4Title = NSLocalizedString("sources.source4.title",
            value: "Intermittent Fasting and Metabolic Health",
            comment: "Title of the fourth scientific source")
    }
}
