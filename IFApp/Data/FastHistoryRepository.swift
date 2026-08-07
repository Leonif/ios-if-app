//
//  FastHistoryRepository.swift
//  IFApp
//
//  Finished fasts, persisted as one JSON file in Documents (not UserDefaults —
//  the list grows without bound and is read as a whole). Records are kept forever;
//  only an explicit delete removes one.
//
//  Bytes that do not decode are never written over (TF-2). A failed read used to
//  return an empty array, and the next `append` then put one fresh record where the
//  whole history had been — a loss with nothing left to recover from and no sign it
//  happened. Now the unreadable file is moved aside first, and if it cannot be moved
//  the repository refuses to write at all.
//
//  The envelope carries a schema version. It is written, and still not read: the
//  migration chain belongs with the first format change, and its place is marked in
//  `readFile()`. Until then this file's promise is narrower than a migration and it
//  is worth being exact about — the old bytes survive, not the old records.
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

    /// What the file turned out to be. Every read *and* every write goes through it,
    /// because the rule the guard is made of — never write on top of bytes we could
    /// not read — is a property of writing, not of loading.
    private enum FileState {
        /// No file, or an empty one. A first launch, not a failure: nothing is put
        /// into quarantine, because there is nothing in it to lose.
        case blank
        case decoded([FastRecord])
        /// Undecodable bytes, now moved aside. The history path is free again.
        case quarantined
        /// Undecodable bytes that could not be moved (disk, permissions). The only
        /// copy of the user's history is still sitting at `fileURL`.
        case stuck

        var records: [FastRecord] {
            if case .decoded(let records) = self { return records }
            return []
        }

        /// A write is allowed unless it would land on data we can neither read nor
        /// keep. `.quarantined` allows it precisely because the old bytes are safe.
        var allowsWrite: Bool {
            if case .stuck = self { return false }
            return true
        }
    }

    private static let currentSchemaVersion = 1
    private static let fileName = "fast-history.json"
    /// Quarantined copies are named `fast-history.corrupt-<epoch>.json` — same folder,
    /// so `simctl get_app_container … data` is all it takes to pull them off a device
    /// or a simulator, and the name says what the file is without a README.
    private static let quarantinePrefix = "fast-history.corrupt-"
    /// How many quarantined copies to keep. A repeating failure would otherwise fill
    /// the container one launch at a time; three is enough to show a pattern.
    private static let quarantineLimit = 3

    private let directory: URL

    /// Documents by default. The directory is a parameter so a unit test can point the
    /// repository at a temp folder and exercise the real file behaviour — the decode
    /// path is what the guard is about, so a fake would test nothing. The app never
    /// passes one: registration in `AppDependencies` stays `FastHistoryRepository()`.
    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.directory = directory
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

    /// Reads before it overwrites, even though it discards what it read: the read is
    /// what puts an unreadable file into quarantine. Without it, wiping the history
    /// (`-uitestReset`) or seeding it would be the one path that still destroys bytes
    /// silently.
    func replaceAll(_ records: [FastRecord]) {
        guard readFile().allowsWrite else { return }
        write(records)
    }

    private func readFile() -> FileState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .blank }
        guard let data = try? Data(contentsOf: fileURL) else {
            return quarantine() ? .quarantined : .stuck
        }
        // A zero-byte file is what an interrupted first write leaves behind. There are
        // no records under it, so quarantining it would only file away emptiness.
        guard !data.isEmpty else { return .blank }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            return quarantine() ? .quarantined : .stuck
        }
        // Migration chain goes here when `FastRecord` first changes shape: compare
        // `envelope.schemaVersion` against `currentSchemaVersion` and upgrade. Today
        // there is one version, so there is nothing to branch on.
        return .decoded(envelope.records)
    }

    /// Moves the unreadable file aside so the next write starts from a clean path.
    /// A rename rather than a copy: it is a single operation, so it cannot half-finish
    /// and leave the caller unable to tell which of the two files is the real one.
    /// Returns whether the bytes are now safe.
    private func quarantine() -> Bool {
        do {
            try FileManager.default.moveItem(at: fileURL, to: freeQuarantineURL())
        } catch {
            return false
        }
        trimQuarantine()
        return true
    }

    /// `fast-history.corrupt-<epoch>.json`, with a counter appended if that name is
    /// taken — two failures inside one second must not make the second one overwrite
    /// the first one's evidence.
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

    /// Keeps the newest `quarantineLimit` copies. Sorting by name is sorting by age:
    /// the epoch is fixed-width for the next two centuries. Copies made within the
    /// same second order arbitrarily between themselves, which only decides which of
    /// two equally old files goes first.
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
    /// The bytes "-seedHistoryCorrupt" leaves on disk: an envelope cut off mid-record,
    /// which is what an interrupted write actually looks like — not random noise.
    /// Kept as one definition so a flow, a unit test and a hand run all corrupt the
    /// file the same way.
    static let corruptFixture = Data(
        #"{"schemaVersion":1,"records":[{"id":"6F1C2A4E-0000-4000-8000-00000000000A","start"#.utf8
    )

    /// Overwrites the history file with bytes that cannot decode. A test hook rather
    /// than a repository feature: the protocol only speaks in records, so the failed
    /// decode path is unreachable through it, and that is the one path the TF-2 guard
    /// exists for. Returns the file it wrote, so the caller can log where to look.
    @discardableResult
    func seedCorruptFile(_ data: Data = corruptFixture) -> URL {
        try? data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
#endif
