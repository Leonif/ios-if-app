//
//  FastHistoryRepository.swift
//  IFApp
//

import Foundation

struct FastHistoryRepository: FastHistoryRepositoryProtocol {
    private struct Envelope: Codable {
        var schemaVersion: Int
        var records: [FastRecord]
    }

    private struct VersionProbe: Decodable {
        var schemaVersion: Int
    }

    private enum FileState {
        case blank
        case decoded([FastRecord])
        case quarantined
        case stuck
        case readOnly([FastRecord])

        var records: [FastRecord] {
            switch self {
            case .decoded(let records), .readOnly(let records): return records
            case .blank, .quarantined, .stuck: return []
            }
        }

        var allowsWrite: Bool {
            switch self {
            case .blank, .decoded, .quarantined: return true
            case .stuck, .readOnly: return false
            }
        }
    }

    private static let currentSchemaVersion = 1
    private static let fileName = "fast-history.json"
    private static let quarantinePrefix = "fast-history.corrupt-"
    private static let quarantineLimit = 3

    private let directory: URL
    private let onLoadFailure: (HistoryLoadFailure) -> Void

    init(
        directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
        onLoadFailure: @escaping (HistoryLoadFailure) -> Void = { _ in }
    ) {
        self.directory = directory
        self.onLoadFailure = onLoadFailure
    }

    private var fileURL: URL {
        directory.appendingPathComponent(Self.fileName)
    }

    func loadAll() -> [FastRecord] {
        readFile().records
    }

    func append(_ record: FastRecord) {
        let state = readFile()
        guard state.allowsWrite else { return }
        write(state.records + [record])
    }

    func delete(id: UUID) {
        let state = readFile()
        guard state.allowsWrite else { return }
        write(state.records.filter { $0.id != id })
    }

    func replaceAll(_ records: [FastRecord]) {
        guard readFile().allowsWrite else { return }
        write(records)
    }

    private func readFile() -> FileState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .blank }
        guard let data = try? Data(contentsOf: fileURL) else { return quarantining(.unreadable) }
        guard !data.isEmpty else { return .blank }
        guard let probe = try? JSONDecoder().decode(VersionProbe.self, from: data) else {
            return quarantining(.decode)
        }
        if probe.schemaVersion > Self.currentSchemaVersion {
            onLoadFailure(.futureSchema)
            return .readOnly((try? JSONDecoder().decode(Envelope.self, from: data))?.records ?? [])
        }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            return quarantining(.decode)
        }
        return .decoded(envelope.records)
    }

    private func quarantining(_ reason: HistoryLoadFailure) -> FileState {
        guard quarantine() else {
            onLoadFailure(.quarantineFailed)
            return .stuck
        }
        onLoadFailure(reason)
        return .quarantined
    }

    private func quarantine() -> Bool {
        do {
            try FileManager.default.moveItem(at: fileURL, to: freeQuarantineURL())
        } catch {
            return false
        }
        trimQuarantine()
        return true
    }

    private func freeQuarantineURL(now: Date = Date()) -> URL {
        let stamp = Int(now.timeIntervalSince1970)
        var url = directory.appendingPathComponent("\(Self.quarantinePrefix)\(stamp).json")
        var attempt = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = directory.appendingPathComponent("\(Self.quarantinePrefix)\(stamp)-\(attempt).json")
            attempt += 1
        }
        return url
    }

    private func trimQuarantine() {
        let manager = FileManager.default
        let names = ((try? manager.contentsOfDirectory(atPath: directory.path)) ?? [])
            .filter { $0.hasPrefix(Self.quarantinePrefix) }
            .sorted()
        guard names.count > Self.quarantineLimit else { return }
        for name in names.dropLast(Self.quarantineLimit) {
            try? manager.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    private func write(_ records: [FastRecord]) {
        let envelope = Envelope(schemaVersion: Self.currentSchemaVersion, records: records)
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

#if DEBUG
extension FastHistoryRepository {
    static let corruptFixture = Data(
        #"{"schemaVersion":1,"records":[{"id":"6F1C2A4E-0000-4000-8000-00000000000A","start"#.utf8
    )

    @discardableResult
    func seedCorruptFile(_ data: Data = corruptFixture) -> URL {
        try? data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    @discardableResult
    func wipeFile() -> URL {
        _ = readFile()
        write([])
        return fileURL
    }

    static let futureSchemaFixture = Data(
        #"{"schemaVersion":99,"records":[{"id":"6F1C2A4E-0000-4000-8000-00000000000C","startTimestamp":1700000000,"endTimestamp":1700061200,"goalHours":16,"planLabel":"16:8"}]}"#.utf8
    )

    @discardableResult
    func seedFutureSchemaFile(_ data: Data = futureSchemaFixture) -> URL {
        try? data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
#endif
