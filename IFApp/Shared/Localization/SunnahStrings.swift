import Foundation

enum SunnahStrings {
    static var title: String { String(localized: "Sunnah.title", defaultValue: "Sunnah reminders") }
    static var weekly: String { String(localized: "Sunnah.weekly", defaultValue: "Mondays and Thursdays") }
    static var whiteDays: String { String(localized: "Sunnah.whiteDays", defaultValue: "White days · 13–15") }
    static var eve: String { String(localized: "Sunnah.eve", defaultValue: "Remind me the day before") }
    static var hour: String { String(localized: "Sunnah.hour", defaultValue: "Hour") }
    static var minute: String { String(localized: "Sunnah.minute", defaultValue: "Minute") }
    static var upcoming: String { String(localized: "Sunnah.upcoming", defaultValue: "Upcoming fasting dates") }
    static var note: String { String(localized: "Sunnah.note", defaultValue: "Free, optional reminders. They do not start a fast or change your plan. IF24 does not calculate dawn or sunset.") }
    static var calendar: String { String(localized: "Sunnah.calendar", defaultValue: "Dates use Umm al-Qura and may differ from local moon sightings. Confirm locally. No voluntary reminders during Ramadan, on Eid, or on 11–13 Dhu al-Hijjah.") }
    static var off: String { String(localized: "Sunnah.off", defaultValue: "Reminders are off") }
    static var checking: String { String(localized: "Sunnah.checking", defaultValue: "Updating reminders…") }
    static var scheduled: String { String(localized: "Sunnah.scheduled", defaultValue: "Reminders scheduled. Reopen IF24 regularly to refresh upcoming dates.") }
    static var denied: String { String(localized: "Sunnah.denied", defaultValue: "Notifications are disabled in iOS Settings.") }
    static var failed: String { String(localized: "Sunnah.failed", defaultValue: "Could not schedule reminders. Try again.") }
    static var settings: String { String(localized: "Sunnah.settings", defaultValue: "Open Settings") }
    static var retry: String { String(localized: "Sunnah.retry", defaultValue: "Try again") }
    static var notification: String { String(localized: "Sunnah.notification", defaultValue: "A Sunnah fasting day is coming tomorrow. Confirm the date and dawn/sunset times locally.") }
}
