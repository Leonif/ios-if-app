import XCTest
@testable import IFApp

final class SunnahScheduleTests: XCTestCase {
    private let zone = TimeZone(identifier: "Europe/Kyiv")!
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    func testSettingsPersistAndCorruptPayloadFallsBackToOff() {
        let name = "SunnahTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let repository = SunnahRepository(defaults: defaults)
        XCTAssertFalse(repository.load().enabled)
        let settings = SunnahSettings(weekly: true, whiteDays: true, minuteOfDay: 1175)
        repository.save(settings)
        XCTAssertEqual(SunnahRepository(defaults: defaults).load(), settings)
        defaults.set(Data("broken".utf8), forKey: "sunnah.reminders.v1")
        XCTAssertFalse(repository.load().enabled)
    }

    func testDefaultIsOffAndEnablingDoesNotChangeTimerOrPlan() {
        let state = AppState()
        XCTAssertTrue(SunnahSchedule.reminders(settings: state.sunnahState.settings,
            now: date("2026-09-11T09:00:00Z"), timeZone: zone).isEmpty)
        let next = rootReducer(state: state, action: SunnahAction.settingsChanged(
            SunnahSettings(weekly: true, whiteDays: false, minuteOfDay: 1200)))
        XCTAssertEqual(next.timerState, state.timerState)
        XCTAssertEqual(next.planState, state.planState)
        XCTAssertEqual(next.sunnahState.delivery, .checking)
    }

    func testWeeklyReminderArrivesOnPreviousLocalDayAndSkipsPastTimes() {
        let reminders = SunnahSchedule.reminders(settings: SunnahSettings(weekly: true),
            now: date("2026-09-11T09:00:00Z"), timeZone: zone, limit: 2)
        XCTAssertEqual(reminders.count, 2)
        XCTAssertEqual(reminders[0].fireDate, date("2026-09-13T17:00:00Z"))
        XCTAssertEqual(reminders[1].fireDate, date("2026-09-16T17:00:00Z"))
        let after = SunnahSchedule.reminders(settings: SunnahSettings(weekly: true),
            now: date("2026-09-13T17:01:00Z"), timeZone: zone, limit: 1)
        XCTAssertEqual(after.first?.fireDate, date("2026-09-16T17:00:00Z"))
    }

    func testDSTUsesLocalHourRatherThanFixedTwentyFourHourOffsets() {
        let ny = TimeZone(identifier: "America/New_York")!
        let reminders = SunnahSchedule.reminders(settings: SunnahSettings(weekly: true),
            now: date("2026-10-31T12:00:00Z"), timeZone: ny, limit: 1)
        // New York falls back Nov 1; Sunday 20:00 is Monday 01:00 UTC.
        XCTAssertEqual(reminders.first?.fireDate, date("2026-11-02T01:00:00Z"))
    }

    func testWhiteDaysOmitThirteenthDhuAlHijjahAndNeverDuplicateWeeklyDays() {
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = zone
        let start = hijri.date(from: DateComponents(year: 1447, month: 12, day: 1, hour: 12))!
        let white = SunnahSchedule.reminders(settings: SunnahSettings(whiteDays: true),
            now: start, timeZone: zone, limit: 2)
        XCTAssertEqual(white.map { hijri.component(.day, from: $0.fastDate) }, [14, 15])
        let combined = SunnahSchedule.reminders(settings: SunnahSettings(weekly: true, whiteDays: true),
            now: start, timeZone: zone)
        XCTAssertEqual(Set(combined.map(\.fastDate)).count, combined.count)
        for item in combined {
            let month = hijri.component(.month, from: item.fastDate)
            let day = hijri.component(.day, from: item.fastDate)
            XCTAssertFalse(month == 12 && (10...13).contains(day))
            XCTAssertFalse(month == 10 && day == 1)
            XCTAssertNotEqual(month, 9)
        }
        XCTAssertLessThanOrEqual(combined.count, 48)
    }

    func testRamadanAndEidAreExcludedEvenWhenTheyMatchWeeklySchedule() {
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = zone
        let start = hijri.date(from: DateComponents(year: 1448, month: 9, day: 1, hour: 12))!
        let reminders = SunnahSchedule.reminders(settings: SunnahSettings(weekly: true, whiteDays: true),
            now: start, timeZone: zone)
        XCTAssertFalse(reminders.isEmpty)
        for item in reminders {
            let parts = hijri.dateComponents([.month, .day], from: item.fastDate)
            XCTAssertNotEqual(parts.month, 9)
            XCTAssertFalse(parts.month == 10 && parts.day == 1)
            XCTAssertGreaterThan(item.fireDate, start)
        }
    }
}
