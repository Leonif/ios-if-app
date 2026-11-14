//
//  FastHistoryRepositoryTests.swift
//  IFAppTests
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

    private var reported: [HistoryLoadFailure] = []

    private func makeRepository() -> FastHistoryRepository {
        FastHistoryRepository(directory: directory) { [self] reason in reported.append(reason) }
    }

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

    func testLoadAllOnEmptyDirectoryReturnsEmptyAndWritesNothing() {
        XCTAssertEqual(makeRepository().loadAll(), [])
        XCTAssertEqual(files, [], "reading an absent history file must not create one")
    }

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

    func testCorruptFixtureFailsToDecode() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        XCTAssertEqual(repository.loadAll(), [], "the fixture must not decode as an envelope")
        XCTAssertEqual(quarantineFiles.count, 1, "a failed decode is what quarantine is for")
    }

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

    func testQuarantineKeepsAtMostThreeCopies() {
        let repository = makeRepository()
        for _ in 0..<4 {
            repository.seedCorruptFile()
            _ = repository.loadAll()
        }

        XCTAssertEqual(quarantineFiles.count, 3)
    }

    func testEmptyFileIsNotQuarantined() {
        try? Data().write(to: directory.appendingPathComponent("fast-history.json"))
        let repository = makeRepository()

        XCTAssertEqual(repository.loadAll(), [])
        repository.append(makeRecord(daysAgo: 1))

        XCTAssertEqual(repository.loadAll().count, 1)
        XCTAssertEqual(quarantineFiles, [], "an empty file is a normal first launch")
    }

    func testReplaceAllQuarantinesBeforeOverwriting() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        repository.replaceAll([makeRecord(daysAgo: 1)])

        XCTAssertEqual(repository.loadAll().count, 1)
        XCTAssertEqual(quarantineFiles.count, 1)
        XCTAssertEqual(bytes(of: quarantineFiles[0]), FastHistoryRepository.corruptFixture)
    }

    // MARK: - schemaVersion

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

    func testFutureSchemaWithUnreadableRecordsIsNotQuarantined() {
        let json = #"{"schemaVersion":99,"records":[{"id":"not-a-record"}]}"#
        try? Data(json.utf8).write(to: directory.appendingPathComponent("fast-history.json"))
        let repository = makeRepository()

        XCTAssertEqual(repository.loadAll(), [], "unreadable shape, so no records")
        XCTAssertEqual(quarantineFiles, [], "but the file is intact and stays where it is")
        XCTAssertEqual(bytes(of: "fast-history.json"), Data(json.utf8))
        XCTAssertEqual(reported, [.futureSchema])
    }

    // MARK: - test hooks

    func testWipeFileClearsAFutureSchemaFileThatReplaceAllRefuses() {
        writeEnvelope(schemaVersion: 99, records: [makeRecord(daysAgo: 1)])
        let repository = makeRepository()

        repository.replaceAll([])
        XCTAssertEqual(repository.loadAll().count, 1, "the guard is what makes the hook necessary")

        repository.wipeFile()

        XCTAssertEqual(repository.loadAll(), [], "the baseline is clean without a reinstall")
        XCTAssertEqual(quarantineFiles, [], "a newer file is intact — nothing to quarantine")
        repository.replaceAll([makeRecord(daysAgo: 2)])
        XCTAssertEqual(repository.loadAll().count, 1, "and seeding works again after it")
    }

    func testWipeFileStillQuarantinesUndecodableBytes() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        repository.wipeFile()

        XCTAssertEqual(repository.loadAll(), [])
        XCTAssertEqual(reported, [.decode])
        XCTAssertEqual(quarantineFiles.count, 1)
        XCTAssertEqual(bytes(of: quarantineFiles[0]), FastHistoryRepository.corruptFixture)
    }

    // MARK: - history_load_failed

    func testFailedDecodeIsReportedOnceWithItsReason() {
        let repository = makeRepository()
        repository.seedCorruptFile()

        _ = repository.loadAll()

        XCTAssertEqual(reported, [.decode], "exactly one report, and it says decode")
    }

    func testEveryReadOfANewerFileReports() {
        writeEnvelope(schemaVersion: 99, records: [makeRecord(daysAgo: 1)])
        let repository = makeRepository()

        _ = repository.loadAll()
        repository.append(makeRecord(daysAgo: 0))

        XCTAssertEqual(reported, [.futureSchema, .futureSchema])
    }

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
