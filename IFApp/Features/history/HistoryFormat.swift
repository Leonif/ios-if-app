//
//  HistoryFormat.swift
//  IFApp
//
//  Dates and times for the history screen. Formats come from the locale (so de gets
//  24h and "Fr 24. Juli"), but the digits are forced Latin like everywhere else in
//  the app, and time tokens are wrapped in an LTR isolate so "8:40 PM" doesn't come
//  apart inside an Arabic sentence.
//

import Foundation

enum HistoryFormat {
    /// The current locale with two things pinned: Western digits, as everywhere else
    /// in the app, and the Gregorian calendar. The calendar matters — ar_SA would
    /// otherwise render Hijri dates here while the streak, the seven-day dots and
    /// every day key in the app are counted on Gregorian days, so the list and the
    /// numbers above it would quietly describe different days.
    ///
    /// Shared with the string catalog's integer substitutions (`Locale.latinDigits`)
    /// so both formatting paths render the same digits on the same screen.
    private static var latinLocale: Locale { .latinDigits }

    private static func formatter(template: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = latinLocale
        f.setLocalizedDateFormatFromTemplate(template)
        return f
    }

    /// "Fri 24 Jul" / "Fr 24. Juli"
    static func rowDate(_ date: Date) -> String {
        formatter(template: "EEEdMMM").string(from: date)
    }

    /// "Thu 23" — the short end of a multi-day range, where the month is already known.
    static func shortDate(_ date: Date) -> String {
        formatter(template: "EEEd").string(from: date)
    }

    /// "Fri 24, 8:40 PM" — the detail panel's Started / Ended values.
    static func dateTime(_ date: Date) -> String {
        "\(shortDate(date)), \(isolate(time(date)))"
    }

    /// "JULY 2026" — the month group header (uppercased at the call site's discretion).
    static func monthTitle(_ date: Date) -> String {
        formatter(template: "MMMMyyyy").string(from: date)
    }

    /// "12 March" — the "since" date in the best-streak line.
    static func sinceDate(_ date: Date) -> String {
        formatter(template: "dMMMM").string(from: date)
    }

    /// "8:40 PM" / "20:40"
    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = latinLocale
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    /// "16h 24m"
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return strings.Duration.hm(total / 3600, (total / 60) % 60)
    }

    /// "152h" — an aggregate of many fasts, where minutes are noise.
    static func totalHours(_ hours: Int) -> String {
        strings.Duration.goalHours(hours)
    }

    /// The row's second line. A same-day fast shows one date and both clock times;
    /// a fast running past 24h shows the date range instead, because the long form
    /// does not survive x1.5 translation growth on one line.
    static func rowSubline(_ record: FastRecord, isRTL: Bool) -> String {
        let arrow = isRTL ? "←" : "→"
        if record.isExtended {
            return "\(rowDate(record.startDate)) \(arrow) \(shortDate(record.endDate)) · \(isolate(time(record.endDate)))"
        }
        return "\(rowDate(record.startDate)) · \(isolate(time(record.startDate))) \(arrow) \(isolate(time(record.endDate)))"
    }

    /// Wraps a digit run in an LTR isolate so bidirectional text can't reorder it.
    private static func isolate(_ text: String) -> String {
        "\u{2066}\(text)\u{2069}"
    }
}
