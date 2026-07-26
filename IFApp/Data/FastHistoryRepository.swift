//
//  FastHistoryRepository.swift
//  IFApp
//
//  Finished fasts, persisted as one JSON file in Documents (not UserDefaults —
//  the list grows without bound and is read as a whole). Records are kept forever;
//  only an explicit delete removes one. The envelope carries a schema version so a
//  future format change can migrate instead of dropping the user's history.
//

import Foundation

protocol FastHistoryRepositoryProtocol {
    func loadAll() -> [FastRecord]
    func append(_ record: FastRecord)
    func delete(id: UUID)
    func replaceAll(_ records: [FastRecord])
}

struct FastHistoryRepository: FastHistoryRepositoryProtocol {
    private struct Envelope: Codable {
        var schemaVersion: Int
        var records: [FastRecord]
    }

    private static let currentSchemaVersion = 1
    private static let fileName = "fast-history.json"

    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(Self.fileName)
    }

    func loadAll() -> [FastRecord] {
        guard let data = try? Data(contentsOf: fileURL),
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return [] }
        return envelope.records
    }

    func append(_ record: FastRecord) {
        var records = loadAll()
        records.append(record)
        write(records)
    }

    func delete(id: UUID) {
        write(loadAll().filter { $0.id != id })
    }

    func replaceAll(_ records: [FastRecord]) {
        write(records)
    }

    private func write(_ records: [FastRecord]) {
        let envelope = Envelope(schemaVersion: Self.currentSchemaVersion, records: records)
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
