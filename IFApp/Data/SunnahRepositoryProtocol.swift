//
//  SunnahRepositoryProtocol.swift
//  IFApp
//

protocol SunnahRepositoryProtocol {
    func load() -> SunnahSettings
    func save(_ settings: SunnahSettings)
    func replace(_ reminders: [SunnahSchedule.Reminder]) async -> Bool
}
