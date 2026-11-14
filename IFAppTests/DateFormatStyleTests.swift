import XCTest
@testable import IFApp

final class DateFormatStyleTests: XCTestCase {

    func testLatinDigitsStylePinsTheGregorianCalendar() {
        XCTAssertEqual(Date.FormatStyle.latinDigits.calendar.identifier, .gregorian)
    }

    func testLatinDigitsStyleCarriesTheLatinDigitsLocale() {
        XCTAssertEqual(Date.FormatStyle.latinDigits.locale.numberingSystem,
                       Locale.NumberingSystem("latn"))
    }

    func testLocaleAloneDoesNotCarryTheCalendarIntoAFormatStyle() {
        XCTAssertEqual(Date.FormatStyle(locale: .latinDigits).calendar, .autoupdatingCurrent)
        XCTAssertEqual(Locale.latinDigits.calendar.identifier, .gregorian)
    }

    func testUpcomingDateShapeRendersAGregorianYearOnAnArabicLocale() {
        var components = Locale.Components(locale: Locale(identifier: "ar_SA"))
        components.numberingSystem = Locale.NumberingSystem("latn")
        components.calendar = .gregorian
        let locale = Locale(components: components)

        let style = Date.FormatStyle(locale: locale,
                                     calendar: locale.calendar,
                                     timeZone: TimeZone(identifier: "UTC")!)
            .day().month().year()
        let rendered = Date(timeIntervalSince1970: 1_789_387_200).formatted(style)
        XCTAssertTrue(rendered.contains("2026"), "expected a Gregorian year, got \(rendered)")
        XCTAssertTrue(rendered.contains("14"), "expected a Gregorian day, got \(rendered)")
        XCTAssertFalse(rendered.contains("1448"), "hijri year leaked through: \(rendered)")
    }
}
