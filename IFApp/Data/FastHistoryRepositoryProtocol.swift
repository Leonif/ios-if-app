//
//  FastHistoryRepositoryProtocol.swift
//  IFApp
//

import Foundation

protocol FastHistoryRepositoryProtocol {
    func loadAll() -> [FastRecord]
    func append(_ record: FastRecord)
    func delete(id: UUID)
    func replaceAll(_ records: [FastRecord])
}
