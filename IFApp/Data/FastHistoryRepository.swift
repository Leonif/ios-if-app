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
//  The envelope's schema version is read as well as written, and it is read *before*
//  the records. That order is the whole of it: a file left by a newer build is not
//  damaged, only younger than this binary, and telling those two apart is what keeps
//  a TestFlight downgrade from filing someone's history away as corrupt. A newer file
//  is handed over read-only — this build would write it back in the older shape.
//
//  There is still no migration chain; its place is marked in `readFile()`. Until it
//  exists this file's promise stays narrower than a migration, and it is worth being
//  exact about — the old bytes survive, not the old records.
//

import Foundation

/// Why a read did not produce today's records. Raw values are the GA4 `reason`
/// parameter of `history_load_failed` — a fixed list, same rule as `trigger`.
enum HistoryLoadFailure: String {
    /// The file is there and cannot be read at all (disk, permissions).
    case unreadable
    /// The bytes are not an envelope this build understands.
    case decode
    /// Written by a newer build. Records may still come back; writing does not.
    case futureSchema = "future_schema"
    /// Unreadable *and* immovable. The only copy is still where it was, and the
    /// repository has stopped writing to keep it that way.
    case quarantineFailed = "quarantine_failed"
}

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

    /// The version on its own. `Envelope` cannot stand in for it: it carries the
    /// records too, so a file whose records this build cannot parse would fail to
    /// decode either way — and the version is exactly what separates "corrupt" from
    /// "written by a newer build".
    private struct VersionProbe: Decodable {
        var schemaVersion: Int
    }

    /// What the file turned out to be. Every read *and* every write goes through it,
    /// because the rule the guard is made of — never write on top of bytes we could
    /// not read — is a property of writing, not of loading. One exception, and it is
    /// not a user's: the DEBUG hook `wipeFile()` reads through here and then writes
    /// anyway, because a suite's baseline is not bytes the guard exists to protect.
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
        /// An envelope from a newer build. Whatever of it this build could read is
        /// handed over, and nothing is written back: the records would go out in the
        /// older shape and the newer ones would be gone. Not quarantined — the file
        /// is intact, and the build that wrote it can still read it.
        case readOnly([FastRecord])

        var records: [FastRecord] {
            switch self {
            case .decoded(let records), .readOnly(let records): return records
            case .blank, .quarantined, .stuck: return []
            }
        }

        /// A write is allowed unless it would land on data we can neither read nor
        /// keep, or on data a newer build understands better than we do.
        /// `.quarantined` allows it precisely because the old bytes are safe.
        var allowsWrite: Bool {
            switch self {
            case .blank, .decoded, .quarantined: return true
            case .stuck, .readOnly: return false
            }
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
    private let onLoadFailure: (HistoryLoadFailure) -> Void

    /// Documents by default. The directory is a parameter so a unit test can point the
    /// repository at a temp folder and exercise the real file behaviour — the decode
    /// path is what the guard is about, so a fake would test nothing.
    ///
    /// `onLoadFailure` is how a failure gets out of here. A closure rather than an
    /// analytics dependency on purpose: this layer knows that a read did not produce
    /// records and why, and nothing about the event catalog. What that *means* is
    /// decided where the repository is registered (`AppDependencies`).
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

    /// Reads before it overwrites, even though it discards what it read: the read is
    /// what puts an unreadable file into quarantine. Without it, wiping the history
    /// (`-uitestReset`) or seeding it would be the one path that still destroys bytes
    /// silently.
    func replaceAll(_ records: [FastRecord]) {
        guard readFile().allowsWrite else { return }
        write(records)
    }

    /// One report per failed read — per call, not per lifetime. A failure that keeps
    /// happening is meant to keep firing: how often it repeats, and whether it repeats
    /// on writes as well as on launches, is the part that says how bad it is.
    private func readFile() -> FileState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .blank }
        guard let data = try? Data(contentsOf: fileURL) else { return quarantining(.unreadable) }
        // A zero-byte file is what an interrupted first write leaves behind. There are
        // no records under it, so quarantining it would only file away emptiness.
        guard !data.isEmpty else { return .blank }
        // Version first, records second. A file from a newer build may well fail to
        // decode into today's `FastRecord`, and reaching the decode before the version
        // would quarantine it as corrupt — destroying, in the name of the guard, the
        // one case the guard cannot tell apart on the bytes alone.
        guard let probe = try? JSONDecoder().decode(VersionProbe.self, from: data) else {
            return quarantining(.decode)
        }
        if probe.schemaVersion > Self.currentSchemaVersion {
            onLoadFailure(.futureSchema)
            // Whatever this build can still make of it. Empty is an honest answer here:
            // the records exist, this binary just cannot read their shape — and with
            // writing off, an empty read costs nothing but a bare screen.
            return .readOnly((try? JSONDecoder().decode(Envelope.self, from: data))?.records ?? [])
        }
        // Migration chain goes here when `FastRecord` first changes shape: a
        // `probe.schemaVersion` below `currentSchemaVersion` is where an upgrade step
        // is inserted. Today there is one version, so there is nothing to branch on.
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            return quarantining(.decode)
        }
        return .decoded(envelope.records)
    }

    /// Moves the unreadable file aside and reports why the read failed.
    ///
    /// When the move fails the reason reported is `quarantineFailed` rather than what
    /// made the bytes unreadable in the first place: only one event goes out per read,
    /// and of the two facts that one is the one still costing the user their history.
    private func quarantining(_ reason: HistoryLoadFailure) -> FileState {
        guard quarantine() else {
            onLoadFailure(.quarantineFailed)
            return .stuck
        }
        onLoadFailure(reason)
        return .quarantined
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

    /// Wipes the history to an empty envelope of the current schema, past the write
    /// guard. A test hook for the same reason as the two seeders: the guard is a
    /// property of writing *a user's* bytes, and a suite's baseline is not that.
    ///
    /// Needed because `replaceAll([])` honours `allowsWrite`, so once a flow seeds a
    /// future-schema file (`.readOnly`, TF-2) every later baseline wipe silently does
    /// nothing and the next flows run on the seeded record — `run.sh all` sorts the
    /// glob as strings, so H15 really does run before H2-H9, and H3/H4/H8 went red on
    /// H15's history. Reinstalling the container hid it, which is why the suite only
    /// caught it in a full run.
    ///
    /// Reads before it writes, so the quarantine path is kept: undecodable bytes are
    /// still moved aside and `onLoadFailure` still fires, exactly as on a normal
    /// launch. The one state it overrules beyond `.readOnly` is `.stuck` — bytes that
    /// could be neither read nor moved. Overwriting those is the point here: the run
    /// needs a clean baseline, and on a simulator container there is nothing under
    /// them worth keeping.
    @discardableResult
    func wipeFile() -> URL {
        _ = readFile()
        write([])
        return fileURL
    }

    /// A well-formed envelope from a schema this build has not shipped yet — the
    /// `readOnly` path (TF-2), as opposed to `corruptFixture`'s `.decode`/quarantine
    /// path. One record, goal reached, so the read-only history renders exactly like
    /// an ordinary one and the only visible difference is that a write after this
    /// does not change the file on disk.
    static let futureSchemaFixture = Data(
        #"{"schemaVersion":99,"records":[{"id":"6F1C2A4E-0000-4000-8000-00000000000C","startTimestamp":1700000000,"endTimestamp":1700061200,"goalHours":16,"planLabel":"16:8"}]}"#.utf8
    )

    /// Overwrites the history file with `futureSchemaFixture`. QA test hook, mirrors
    /// `seedCorruptFile` — same reasoning: the protocol only speaks in records, and a
    /// newer-than-this-build envelope is not something it can express.
    @discardableResult
    func seedFutureSchemaFile(_ data: Data = futureSchemaFixture) -> URL {
        try? data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
#endif
