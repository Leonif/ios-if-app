import XCTest
@testable import IFApp

/// `Locale.latinDigits` pins two things — Western digits and the Gregorian calendar —
/// and every `DateFormatter` in the app gets both just by taking that locale. A
/// `Date.FormatStyle` does not: its calendar is a separate initialiser argument with
/// its own default, so `Date.FormatStyle(locale: .latinDigits)` pinned the digits and
/// silently left the calendar on the device's. On an Arabic device that is the Islamic
/// calendar, and the Sunnah settings listed the upcoming fasts as "3 ربيع الآخر، 1448 هـ"
/// while the schedule behind them was counted in Gregorian days.
final class DateFormatStyleTests: XCTestCase {

    func testLatinDigitsStylePinsTheGregorianCalendar() {
        XCTAssertEqual(Date.FormatStyle.latinDigits.calendar.identifier, .gregorian)
    }

    func testLatinDigitsStyleCarriesTheLatinDigitsLocale() {
        XCTAssertEqual(Date.FormatStyle.latinDigits.locale.numberingSystem,
                       Locale.NumberingSystem("latn"))
    }

    /// The trap itself, asserted so it cannot come back unnoticed: passing only
    /// `locale:` leaves the calendar on `.autoupdatingCurrent`, whatever the locale
    /// handed in says its calendar is.
    func testLocaleAloneDoesNotCarryTheCalendarIntoAFormatStyle() {
        XCTAssertEqual(Date.FormatStyle(locale: .latinDigits).calendar, .autoupdatingCurrent)
        XCTAssertEqual(Locale.latinDigits.calendar.identifier, .gregorian)
    }

    /// The Sunnah list's own shape, built the way `Locale.latinDigits` builds itself but
    /// on an explicit Arabic/Saudi base, so the assertion does not depend on what the
    /// test host's own locale happens to be: the year has to read as a Gregorian one in
    /// Western digits.
    func testUpcomingDateShapeRendersAGregorianYearOnAnArabicLocale() {
        var components = Locale.Components(locale: Locale(identifier: "ar_SA"))
        components.numberingSystem = Locale.NumberingSystem("latn")
        components.calendar = .gregorian
        let locale = Locale(components: components)

        let style = Date.FormatStyle(locale: locale,
                                     calendar: locale.calendar,
                                     timeZone: TimeZone(identifier: "UTC")!)
            .day().month().year()
        // 2026-09-14T12:00:00Z — 2 Rabi al-Thani 1448 on Umm al-Qura.
        let rendered = Date(timeIntervalSince1970: 1_789_387_200).formatted(style)
        XCTAssertTrue(rendered.contains("2026"), "expected a Gregorian year, got \(rendered)")
        XCTAssertTrue(rendered.contains("14"), "expected a Gregorian day, got \(rendered)")
        XCTAssertFalse(rendered.contains("1448"), "hijri year leaked through: \(rendered)")
    }
}
