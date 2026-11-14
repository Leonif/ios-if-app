//
//  HistoryExport.swift
//  IFApp
//

import Foundation

enum HistoryExport {
    static let header = "start,end,duration_minutes,goal_hours,goal_reached,phase"

    private static let newline = "\r\n"

    static func csv(records: [FastRecord]) -> String {
        let chronological = records.sorted { $0.startTimestamp < $1.startTimestamp }
        return ([header] + chronological.map(row)).joined(separator: newline) + newline
    }

    private static func row(_ record: FastRecord) -> String {
        [
            timestamp(record.startDate),
            timestamp(record.endDate),
            String(Int(record.duration / 60)),
            String(Int(record.goalHours.rounded())),
            record.goalReached ? "true" : "false",
            record.reachedPhase.exportValue,
        ].joined(separator: ",")
    }

    private static func timestamp(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        f.timeZone = .current
        return f
    }()

    static func fileName(dayKey: String) -> String {
        "IF24-history-\(dayKey).csv"
    }
}
