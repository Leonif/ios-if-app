//
//  FastHistoryRepositoryTests.swift
//  IFAppTests
//
//  The data layer's file behaviour, including the TF-2 quarantine. Every case runs
//  against a fresh temp directory (`FastHistoryRepository(directory:)`) — never the
//  test host's Documents, which is shared between runs and would make one test's
//  leftovers the next test's input.
//
//  Still absent from the TF-2 acceptance list: the schemaVersion read-only mode and
//  the `history_load_failed` analytics spy. Neither is implemented yet, so a test for
//  either would be a test of nothing.
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

    private func makeRepository() -> FastHistoryRepository {
        FastHistoryRepository(directory: directory)
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
}
