//
//  SunnahSettings.swift
//  IFApp
//

struct SunnahSettings: Codable, Equatable, Sendable {
    var weekly = false
    var whiteDays = false
    var minuteOfDay = 20 * 60
    var enabled: Bool { weekly || whiteDays }

    var analyticsMode: String {
        switch (weekly, whiteDays) {
        case (true, true): return "both"
        case (true, false): return "weekly"
        case (false, true): return "white_days"
        case (false, false): return "off"
        }
    }

    static func clamped(minuteOfDay: Int) -> Int { min(1439, max(0, minuteOfDay)) }
}
