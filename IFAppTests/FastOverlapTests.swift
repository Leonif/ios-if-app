//
//  FastOverlapTests.swift
//  IFAppTests
//
//  The boundary cases of the overlap guard (TF-4). They are the whole of it: the
//  defect it fixes was two records for one night, and the reason nobody wrote the
//  guard sooner is that "overlap" reads obvious until three specific spans are put
//  next to each other — end-to-end, nested, and identical.
//

import XCTest
@testable import IFApp

final class FastOverlapTests: XCTestCase {
    /// Midnight of an arbitrary day, so every span below reads in whole hours.
    private let base: Double = 1_754_000_000

    private func record(_ fromHour: Double, _ toHour: Double) -> FastRecord {
        FastRecord(id: UUID(),
                   startTimestamp: base + fromHour * 3600,
                   endTimestamp: base + toHour * 3600,
                   goalHours: 16,
                   planLabel: "16:8")
    }

    private func span(_ fromHour: Double, _ toHour: Double) -> (Double, Double) {
        (base + fromHour * 3600, base + toHour * 3600)
    }

    func testTouchingEndToEndIsNotAnOverlap() {
        let saved = record(0, 16)
        let (start, end) = span(16, 30)
        XCTAssertFalse(saved.overlaps(start: start, end: end))
        // And the mirror: a span ending exactly where a saved one begins.
        let (s2, e2) = span(-8, 0)
        XCTAssertFalse(saved.overlaps(start: s2, end: e2))
    }

    func testNestedIntervalIsAnOverlap() {
        let saved = record(0, 16)
        let (start, end) = span(4, 8)
        XCTAssertTrue(saved.overlaps(start: start, end: end))
        // Containing the saved one is the same answer from the other side.
        let (s2, e2) = span(-2, 20)
        XCTAssertTrue(saved.overlaps(start: s2, end: e2))
    }

    func testIdenticalBoundsAreAnOverlap() {
        let saved = record(0, 16)
        let (start, end) = span(0, 16)
        XCTAssertTrue(saved.overlaps(start: start, end: end))
    }

    func testPartialOverlapFromEitherSide() {
        let saved = record(0, 16)
        XCTAssertTrue(saved.overlaps(start: span(-4, 2).0, end: span(-4, 2).1))
        XCTAssertTrue(saved.overlaps(start: span(14, 20).0, end: span(14, 20).1))
    }

    /// A one-second sliver still counts. The guard is about whether two records can
    /// both claim the same time, and a second of double-counted fasting is the same
    /// defect as an hour of it, only harder to see.
    func testOneSecondOfSharedTimeIsAnOverlap() {
        let saved = record(0, 16)
        XCTAssertTrue(saved.overlaps(start: base + 16 * 3600 - 1, end: base + 20 * 3600))
    }

    func testFirstOverlapNamesTheNewestBlockingRecord() {
        let older = record(-30, -20)
        let newer = record(0, 16)
        let unrelated = record(40, 50)
        let records = [unrelated, older, newer]
        // A span crossing both saved fasts is answered with the newer one — the one
        // the person is likeliest to recognise from its own date.
        let found = FastRecord.firstOverlap(in: records,
                                            start: base - 25 * 3600,
                                            end: base + 4 * 3600)
        XCTAssertEqual(found?.id, newer.id)
    }

    func testFirstOverlapIsNilWhenTheIntervalIsFree() {
        let records = [record(0, 16), record(-30, -20)]
        XCTAssertNil(FastRecord.firstOverlap(in: records,
                                             start: base + 16 * 3600,
                                             end: base + 24 * 3600))
    }
}
