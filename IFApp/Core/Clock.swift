//
//  Clock.swift
//  IFApp
//
//  The one place that reads wall-clock time for thunks (kept out of reducers/views).
//

import Foundation

enum Clock {
    static func now() -> Date { Date() }

    static func minuteOfDay(_ date: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
