//
//  FastHistoryRepositoryTests.swift
//  IFAppTests
//
//  The data layer's file behaviour, including the TF-2 quarantine. Every case runs
//  against a fresh temp directory (`FastHistoryRepository(directory:)`) — never the
//  test host's Documents, which is shared between runs and would make one test's
//  leftovers the next test's input.
//
//  The TF-2 acceptance list is covered end to end here, including the schemaVersion
//  read-only mode and the `history_load_failed` reasons. The failure reports are taken
//  through the same closure the app wires to analytics in `AppDependencies`, so a spy
//  on it sees exactly what GA4 would.
//

import XCTest
@testable import IFApp

final class FastHistoryRepositoryTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IFAppTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    /// Every failure the repository reports, in order. The app hands this same closure
    /// to analytics, so counting on it is counting the events GA4 would receive.
    private var reported: [HistoryLoadFailure] = []

    private func makeRepository() -> FastHistoryRepository {
        FastHistoryRepository(directory: directory) { [self] reason in reported.append(reason) }
    }

    /// An envelope written by hand, so the version can be something this build does
    /// not have. `JSONEncoder` on `Envelope` would always stamp the current one.
    private func writeEnvelope(schemaVersion: Int, records: [FastRecord]) {
        let recordsJSON = records.map {
            """
            {"id":"\($0.id.uuidString)","startTimestamp":\($0.startTimestamp),\
            "endTimestamp":\($0.endTimestamp),"goalHours":\($0.goalHours),\
            "planLabel":"\($0.planLabel)"}
            """
        }
        let json = #"{"schemaVersion":\#(schemaVersion),"records":[\#(recordsJSON.joined(separator: ","))]}"#
        try? Data(json.utf8).write(to: directory.appendingPathComponent("fast-history.json"))
    }

    private func makeRecord(daysAgo: Int) -> FastRecord {
        let start = Date().timeIntervalSince1970 - Double(daysAgo) * 86_400
        return FastRecord(
            id: UUID(),
            startTimestamp: start,
            endTimestamp: start + 16 * 3600,
            goalHours: 16,
            planLabel: "16:8"
        )
    }

    private var files: [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []).sorted()
    }

    private var quarantineFiles: [String] {
        files.filter { $0.hasPrefix("fast-history.corrupt-") }
    }

    private func bytes(of name: String) -> Data? {
        try? Data(contentsOf: directory.appendingPathComponent(name))
    }

    /// First launch: no file is not a failure, and nothing is written just by looking.
    func testLoadAllOnEmptyDirectoryReturnsEmptyAndWritesNothing() {
        XCTAssertEqual(makeRepository().loadAll(), [])
        XCTAssertEqual(files, [], "reading an absent history file must not create one")
    }

    /// The write path survives a round trip through JSON and a second instance —
    /// i.e. the records come off disk, not out of an in-memory cache.
    func testAppendRoundTripsThroughDisk() {
        let repository = makeRepository()
        let records = (0..<3).map(makeRecord(daysAgo:))
        records.forEach(repository.append)

        XCTAssertEqual(makeRepository().loadAll(), records)
        XCTAssertEqual(files, ["fast-history.json"])
    }

    func testDeleteRemovesOnlyTheNamedRecord() {
        let repository = makeRepository()
        let records = (0..<3).map(makeRecord(daysAgo:))
        records.forEach(repository.append)

        repository.delete(id: records[1].id)

        XCTAssertEqual(makeRepository().loadAll(), [records[0], records[2]])
    }

    /// Pins the `-seedHistoryCorrupt` fixture: the bytes it writes really are
    /// undecodable. If someone edited the fixture into something that happens to parse,
    /// the seed would go on looking useful while testing nothing — and so would every
    /// quarantine case below it, which all start from this fixture.
    func testCorruptFixtureFailsToDecode() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        XCTAssertEqual(repository.loadAll(), [], "the fixture must not decode as an envelope")
        XCTAssertEqual(quarantineFiles.count, 1, "a failed decode is what quarantine is for")
    }

    /// TF-2, the case the guard exists for. Before the fix the append put one fresh
    /// record where the whole history had been and left nothing behind; now the old
    /// bytes are sitting next to it, byte for byte, and can be pulled out of the
    /// container.
    func testAppendAfterCorruptFileKeepsTheOldBytesInQuarantine() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        repository.append(makeRecord(daysAgo: 1))

        XCTAssertEqual(repository.loadAll().count, 1, "the new record is written to a clean file")
        XCTAssertEqual(quarantineFiles.count, 1)
        XCTAssertEqual(bytes(of: quarantineFiles[0]),
                       FastHistoryRepository.corruptFixture,
                       "the quarantined copy must be the original bytes, unaltered")
        XCTAssertTrue(files.contains("fast-history.json"))
    }

    /// The quarantined copy is evidence, not a working file: once set aside it is never
    /// touched again by ordinary use.
    func testFurtherWritesLeaveTheQuarantinedCopyAlone() {
        let repository = makeRepository()
        repository.seedCorruptFile()
        repository.append(makeRecord(daysAgo: 3))
        let quarantined = quarantineFiles

        repository.append(makeRecord(daysAgo: 2))
        repository.append(makeRecord(daysAgo: 1))

        XCTAssertEqual(repository.loadAll().count, 3)
        XCTAssertEqual(quarantineFiles, quarantined, "no second copy, no rename")
        XCTAssertEqual(bytes(of: quarantined[0]), FastHistoryRepository.corruptFixture)
    }

    /// A repeating failure must not fill the container one launch at a time. Four
    /// failures, three copies kept.
    func testQuarantineKeepsAtMostThreeCopies() {
        let repository = makeRepository()
        for _ in 0..<4 {
            repository.seedCorruptFile()
            _ = repository.loadAll()
        }

        XCTAssertEqual(quarantineFiles.count, 3)
    }

    /// An empty file is what an interrupted first write leaves; there are no records
    /// under it, so filing it away would only archive emptiness.
    func testEmptyFileIsNotQuarantined() {
        try? Data().write(to: directory.appendingPathComponent("fast-history.json"))
        let repository = makeRepository()

        XCTAssertEqual(repository.loadAll(), [])
        repository.append(makeRecord(daysAgo: 1))

        XCTAssertEqual(repository.loadAll().count, 1)
        XCTAssertEqual(quarantineFiles, [], "an empty file is a normal first launch")
    }

    /// `replaceAll` is the one write that discards what it reads — wiping the history
    /// or seeding it. It still has to read first, or it would be the remaining path
    /// that destroys unreadable bytes silently.
    func testReplaceAllQuarantinesBeforeOverwriting() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        repository.replaceAll([makeRecord(daysAgo: 1)])

        XCTAssertEqual(repository.loadAll().count, 1)
        XCTAssertEqual(quarantineFiles.count, 1)
        XCTAssertEqual(bytes(of: quarantineFiles[0]), FastHistoryRepository.corruptFixture)
    }

    // MARK: - schemaVersion

    /// A file from a newer build: the records this binary can still read come back, and
    /// nothing goes in. Writing would put them back in today's shape, which is how a
    /// TestFlight downgrade would quietly cost someone whatever the newer format added.
    func testFutureSchemaReturnsRecordsAndRefusesToWrite() {
        writeEnvelope(schemaVersion: 99, records: [makeRecord(daysAgo: 2), makeRecord(daysAgo: 1)])
        let original = bytes(of: "fast-history.json")
        let repository = makeRepository()

        XCTAssertEqual(repository.loadAll().count, 2, "a newer file is still read")

        repository.append(makeRecord(daysAgo: 0))
        repository.delete(id: repository.loadAll()[0].id)
        repository.replaceAll([])

        XCTAssertEqual(bytes(of: "fast-history.json"), original, "no write may touch a newer file")
        XCTAssertEqual(quarantineFiles, [], "a newer file is not damaged — nothing to quarantine")
    }

    /// The case that decides where the version read goes. Records this build cannot
    /// parse would fail the envelope decode, and a decode failure is what quarantine
    /// answers — so reading the version second would file away an intact history the
    /// newer build is still using. Reading it first is the whole fix.
    func testFutureSchemaWithUnreadableRecordsIsNotQuarantined() {
        let json = #"{"schemaVersion":99,"records":[{"id":"not-a-record"}]}"#
        try? Data(json.utf8).write(to: directory.appendingPathComponent("fast-history.json"))
        let repository = makeRepository()

        XCTAssertEqual(repository.loadAll(), [], "unreadable shape, so no records")
        XCTAssertEqual(quarantineFiles, [], "but the file is intact and stays where it is")
        XCTAssertEqual(bytes(of: "fast-history.json"), Data(json.utf8))
        XCTAssertEqual(reported, [.futureSchema])
    }

    // MARK: - history_load_failed

    /// One event per failed read, with the reason that names what happened.
    func testFailedDecodeIsReportedOnceWithItsReason() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        _ = repository.loadAll()

        XCTAssertEqual(reported, [.decode], "exactly one report, and it says decode")
    }

    /// Every read reports, deliberately: a `future_schema` on launch and again on the
    /// next write attempt is what tells a downgrade apart from a one-off.
    func testEveryReadOfANewerFileReports() {
        writeEnvelope(schemaVersion: 99, records: [makeRecord(daysAgo: 1)])
        let repository = makeRepository()

        _ = repository.loadAll()
        repository.append(makeRecord(daysAgo: 0))

        XCTAssertEqual(reported, [.futureSchema, .futureSchema])
    }

    /// Bytes that cannot be read at all, as opposed to bytes that do not decode. They
    /// go into quarantine the same way — the difference is only what gets reported.
    func testUnreadableFileIsReportedAsUnreadable() throws {
        let fileURL = directory.appendingPathComponent("fast-history.json")
        try Data(#"{"schemaVersion":1,"records":[]}"#.utf8).write(to: fileURL)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: fileURL.path)
        try XCTSkipUnless((try? Data(contentsOf: fileURL)) == nil, "the runner can read anything")
        let repository = makeRepository()

        _ = repository.loadAll()

        XCTAssertEqual(reported, [.unreadable])
        XCTAssertEqual(quarantineFiles.count, 1, "unreadable bytes are kept, not dropped")
    }

    /// The worst case: unreadable and immovable. Nothing is written from here on —
    /// the only copy of the history is still sitting where it was, and an append would
    /// be the thing that finally destroys it.
    func testUnmovableFileReportsQuarantineFailedAndStopsWriting() throws {
        let repository = makeRepository()
        repository.seedCorruptFile()
        try FileManager.default.setAttributes([.posixPermissions: 0o500],
                                              ofItemAtPath: directory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700],
                                                   ofItemAtPath: directory.path)
        }

        _ = repository.loadAll()
        repository.append(makeRecord(daysAgo: 1))

        try XCTSkipUnless(quarantineFiles.isEmpty, "the runner can write a locked directory")
        XCTAssertEqual(reported, [.quarantineFailed, .quarantineFailed])
        XCTAssertEqual(bytes(of: "fast-history.json"), FastHistoryRepository.corruptFixture,
                       "the bytes we could neither read nor move are still there")
    }
}
