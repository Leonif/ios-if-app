//
//  HistoryFormat.swift
//  IFApp
//

import Foundation

enum HistoryFormat {
    private static var latinLocale: Locale { .latinDigits }

    private static func formatter(template: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = latinLocale
        f.setLocalizedDateFormatFromTemplate(template)
        return f
    }

    static func rowDate(_ date: Date) -> String {
        formatter(template: "EEEdMMM").string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        formatter(template: "EEEd").string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        "\(shortDate(date)), \(BidiText.isolate(time(date)))"
    }

    static func monthTitle(_ date: Date) -> String {
        formatter(template: "MMMMyyyy").string(from: date)
    }

    static func sinceDate(_ date: Date) -> String {
        formatter(template: "dMMMM").string(from: date)
    }

    static func weekdayNarrow(_ date: Date) -> String {
        formatter(template: "EEEEE").string(from: date)
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = latinLocale
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return strings.Duration.hm(total / 3600, (total / 60) % 60)
    }

    static func summaryDuration(_ seconds: TimeInterval) -> String {
        let hours = max(0, seconds / 3600)
        if hours >= 48 {
            return strings.Duration.daysShort(max(1, Int((hours / 24).rounded())))
        }
        return strings.Duration.goalHours(max(seconds > 0 ? 1 : 0, Int(hours.rounded())))
    }

    static func totalHours(_ hours: Int) -> String {
        strings.Duration.goalHours(hours)
    }

    static func rowSubline(_ record: FastRecord, isRTL: Bool) -> String {
        let arrow = isRTL ? "←" : "→"
        if record.isExtended {
            return "\(rowDate(record.startDate)) \(arrow) \(shortDate(record.endDate)) · \(BidiText.isolate(time(record.endDate)))"
        }
        return "\(rowDate(record.startDate)) · \(BidiText.isolate(time(record.startDate))) \(arrow) \(BidiText.isolate(time(record.endDate)))"
    }
}
