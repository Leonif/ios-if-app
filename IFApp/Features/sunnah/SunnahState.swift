import Foundation

struct SunnahState: Equatable, Sendable {
    enum Delivery: Equatable, Sendable {
        case off, checking, scheduled, denied, failed

        static func resolve(enabled: Bool, otherwise: Delivery) -> Delivery { enabled ? otherwise : .off }
    }
    var settings = SunnahSettings()
    var delivery: Delivery = .off
    var upcoming: [Date] = []
}
