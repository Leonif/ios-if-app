//
//  strings.swift
//  IFApp
//
//  Type-safe access to the Localizable.xcstrings String Catalog. Keys are the
//  English source text (the catalog's source language); each accessor resolves the
//  current locale via String(localized:). Add a case here, then add the matching
//  key + translations in Localizable.xcstrings.
//

import Foundation

extension Locale {
    /// The current locale with two things pinned: Western digits and the Gregorian
    /// calendar.
    ///
    /// Digits matter because the app mixes two formatting paths. Durations and dates
    /// go through `String(format:)` and `HistoryFormat`, which never localise digits,
    /// so they always read "118". An `Int` interpolated into `String(localized:)` is
    /// formatted by the locale instead, so in Arabic the same screen rendered "٦"
    /// beside "118". Pinning the numbering system puts both paths on one system.
    ///
    /// The language is left untouched, so translations still resolve normally and
    /// plural rules still come from the real locale.
    static var latinDigits: Locale {
        var components = Locale.Components(locale: .current)
        components.numberingSystem = Locale.NumberingSystem("latn")
        components.calendar = .gregorian
        return Locale(components: components)
    }
}

enum strings {
    enum Phase {
        static var fed: String { String(localized: "Fed") }
        static var sugar: String { String(localized: "Sugar") }
        static var fat: String { String(localized: "Fat") }
        static var ketosis: String { String(localized: "Ketosis") }
        static var autophagy: String { String(localized: "Autophagy") }
    }

    enum Editorial {
        static var idle: String { String(localized: "Start whenever you're ready, or log your last meal to pick up a fast already in progress.") }
        static var complete: String { String(localized: "Fast complete. Your eating window is ready. Refuel gently.") }
        static var windowOpen: String { String(localized: "Fast complete. Your eating window is open. Refuel gently.") }
        static var fed: String { String(localized: "Still digesting. Insulin is up and your body is storing the energy from your last meal.") }
        static var sugar: String { String(localized: "Glucose is easing down. Your body is leaning on its glycogen stores for fuel.") }
        static var fat: String { String(localized: "Glycogen is running low. Fat is becoming your main source of energy.") }
        static var ketosis: String { String(localized: "Ketones are climbing. You're well into fat-burning now.") }
        static var autophagy: String { String(localized: "Deep in the fast. Autophagy is recycling what your cells no longer need.") }
        static var windowClosed: String { String(localized: "Your eating window has closed. Every minute since already counts - continue your fast whenever you're ready.") }

        /// Editorial shown once the goal is reached (overtime). `hours` = plan goal in hours.
        static func goalReached(_ hours: Int) -> String {
            String(format: String(localized: "You've reached your %d-hour goal. Every minute now is deeper autophagy."), hours)
        }

        /// "Autophagy begins in 2h 36m"
        static func beginsIn(_ phase: String, _ when: String) -> String {
            String(format: String(localized: "%@ begins in %@"), phase, when)
        }
    }

    enum Timer {
        static var elapsedCaption: String { String(localized: "ELAPSED") }
        static var fastComplete: String { String(localized: "FAST COMPLETE") }
        static var goalReached: String { String(localized: "GOAL REACHED") }
        static var eatingWindow: String { String(localized: "EATING WINDOW") }
        static var windowClosed: String { String(localized: "WINDOW CLOSED") }
        static var fastingSoFar: String { String(localized: "Fasting so far") }
        static var start: String { String(localized: "Start") }
        static var dailyFast: String { String(localized: "Daily fast") }
        static var lastMeal: String { String(localized: "Last meal · ") }

        /// "Closes 8:00 PM" — the caption under the eating-window countdown.
        static func closesAt(_ time: String) -> String {
            String(localized: "Closes \(time)")
        }

        /// Overtime pill in the center, e.g. "Goal 16:00 · +0:24".
        ///
        /// Goes through `String(format:)` rather than an interpolated
        /// `String(localized:)` so a translation can reorder the two arguments with
        /// `%1$@` / `%2$@` — Arabic needs the goal and the overage the other way
        /// round. Interpolation binds them by position and gives a locale no way to
        /// swap them. Same shape as `Editorial.beginsIn` above.
        static func goalOvertime(_ goal: String, _ over: String) -> String {
            String(format: String(localized: "Goal %@ · +%@"), goal, over)
        }

        /// Static phase chip shown in the overtime state.
        static var deepAutophagy: String { String(localized: "Deep autophagy - cellular repair") }
    }

    enum Footer {
        static var started: String { String(localized: "Started") }
        static var elapsed: String { String(localized: "Elapsed") }
        static var endFast: String { String(localized: "End fast") }
        static var fasted: String { String(localized: "Fasted") }
        static var windowOpens: String { String(localized: "Window opens") }
        static var reset: String { String(localized: "Reset") }
        static var startEatingWindow: String { String(localized: "Start eating window") }
        static var startFast: String { String(localized: "Start fast") }
        static var continueFasting: String { String(localized: "Continue fasting") }
        static var skip: String { String(localized: "Skip") }
        static var goalStat: String { String(localized: "Goal") }
        static var over: String { String(localized: "Over") }

        /// "Goal · 16h"
        static func goal(_ hours: String) -> String {
            String(localized: "Goal · \(hours)")
        }
    }

    enum Reset {
        static var confirmTitle: String { String(localized: "Reset this fast?") }
        static var confirmMessage: String { String(localized: "This discards the current fast and returns to the start.") }
        static var confirmAction: String { String(localized: "Reset fast") }
        static var keepFasting: String { String(localized: "Keep fasting") }
        static var cancel: String { String(localized: "Cancel") }
    }

    enum Sheet {
        static var fastingPlan: String { String(localized: "Fasting plan") }
        static var tapToChange: String { String(localized: "Tap to change") }
        static var eatingWindow: String { String(localized: "Eating window") }
        static var done: String { String(localized: "Done") }
        static var whenDidYouEat: String { String(localized: "When did you last eat?") }
        static var backdateHint: String { String(localized: "We'll back-date your fast so the timer stays accurate.") }
        static var confirm: String { String(localized: "Confirm") }
    }

    enum Window {
        static var p14_10: String { String(localized: "10:00 AM - 8:00 PM") }
        static var p16_8: String { String(localized: "12:00 - 8:00 PM") }
        static var p18_6: String { String(localized: "2:00 - 8:00 PM") }
        static var p20_4: String { String(localized: "4:00 - 8:00 PM") }
    }

    enum Meal {
        static var today: String { String(localized: "Today") }
        static var yesterday: String { String(localized: "Yesterday") }
        static var now: String { String(localized: "Now") }
        static var justNow: String { String(localized: "Just now") }
        static var startingFresh: String { String(localized: "starting fresh") }

        /// "2 days ago" (locale-aware plural)
        static func daysAgo(_ n: Int) -> String { String(localized: "\(n) days ago", locale: .latinDigits) }

        /// "2h 43m in"
        static func noteIn(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %02dm in"), h, m)
        }

        /// "Fast counts from 7:00 PM · 2h 40m in"
        static func fastCountsFrom(_ from: String, _ note: String) -> String {
            String(localized: "Fast counts from \(from) · \(note)")
        }

        // MARK: Last-meal picker

        static var chip1h: String { String(localized: "1h", comment: "Meal picker chip: one hour ago") }
        static var chip3h: String { String(localized: "3h", comment: "Meal picker chip: three hours ago") }
        static var chipLastNight: String { String(localized: "Last night") }
        static var setExactTime: String { String(localized: "Set exact time") }
        static var scaleLimitNote: String { String(localized: "That's as far back as we go.") }
        static var windowClosedOverline: String { String(localized: "Eating window closed") }
        static var scaleA11yLabel: String { String(localized: "Time since last meal") }

        // The readout is a whole template per shape, never a duration glued to an
        // "ago": that word leads in de/es/fr/ar and trails in uk/pl/ja/ko.

        /// "40m ago"
        static func agoMinutes(_ m: Int) -> String {
            String(format: String(localized: "%dm ago"), m)
        }
        /// "3h ago"
        static func agoHours(_ h: Int) -> String {
            String(format: String(localized: "%dh ago"), h)
        }
        /// "2h 40m ago"
        static func agoRelative(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %dm ago"), h, m)
        }
        /// "1d 3h ago"
        static func agoDays(_ d: Int, _ h: Int) -> String {
            String(format: String(localized: "%dd %dh ago"), d, h)
        }
        /// "7d ago"
        static func agoDaysOnly(_ d: Int) -> String {
            String(format: String(localized: "%dd ago"), d)
        }

        /// "Today at 7:50 AM"
        static func todayAt(_ time: String) -> String { String(localized: "Today at \(time)") }
        /// "Yesterday at 8:00 PM"
        static func yesterdayAt(_ time: String) -> String { String(localized: "Yesterday at \(time)") }
        /// "Sat 18 Jul at 10:30 AM"
        static func dateAt(_ date: String, _ time: String) -> String {
            String(localized: "\(date) at \(time)")
        }

        /// Ribbon tick label, hours — "3h". Deliberately as short as the tick is wide.
        static func scaleTickHours(_ h: Int) -> String {
            String(format: String(localized: "%dh"), h)
        }
        /// Ribbon tick label, days — "3d".
        static func scaleTickDays(_ d: Int) -> String {
            String(format: String(localized: "%dd"), d)
        }
    }

    enum Duration {
        /// "13h 04m"
        static func hm(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %02dm"), h, m)
        }
        /// "2h 6m"
        static func hmShort(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %dm"), h, m)
        }
        /// "36m"
        static func minutes(_ m: Int) -> String {
            String(format: String(localized: "%dm"), m)
        }
        /// "16h"
        static func goalHours(_ h: Int) -> String {
            String(format: String(localized: "%dh"), h)
        }
    }

    enum Streak {
        /// "3-day streak" — the flame pill on the main screen.
        static func badge(_ days: Int) -> String {
            String(localized: "\(days)-day streak", locale: .latinDigits)
        }
        /// Milestone card title, e.g. "7 days in a row".
        static func milestoneTitle(_ days: Int) -> String {
            String(localized: "\(days) days in a row", locale: .latinDigits)
        }
        static var milestoneSubtitle: String { String(localized: "You've hit your fasting goal every day. Keep the rhythm going.") }
        static var milestoneClose: String { String(localized: "Keep going") }
    }

    enum History {
        static var title: String { String(localized: "History") }
        static var streakOverline: String { String(localized: "Current streak") }
        static var lastSevenDays: String { String(localized: "Last 7 days") }
        static var statFasts: String { String(localized: "Fasts") }
        static var statTotal: String { String(localized: "Total") }
        static var statLongest: String { String(localized: "Longest") }
        static var extended: String { String(localized: "Extended") }
        static var started: String { String(localized: "Started") }
        static var ended: String { String(localized: "Ended") }
        static var delete: String { String(localized: "Delete") }
        static var deleteTitle: String { String(localized: "Delete this fast?") }
        static var deleteBody: String { String(localized: "It will be removed from your history and your totals.") }
        static var cancel: String { String(localized: "Cancel") }
        static var emptyTitle: String { String(localized: "Your fasts gather here") }
        static var emptyBody: String { String(localized: "Every finished fast is saved with its length, plan and times - so you can look back on the rhythm you are building.") }
        static var emptyCta: String { String(localized: "Start a fast") }
        static var firstNote: String { String(localized: "First one saved. Finish tomorrow's fast and your streak begins.") }
        static var savedToHistory: String { String(localized: "Saved to your history") }

        /// Streak unit beside the big number. The number is drawn separately (display
        /// type), so the catalog's plural variants carry the word alone — the CLDR
        /// categories live there, never as a `days == 1` here.
        static func daysInARow(_ days: Int) -> String {
            String(localized: "history.streak.unit",
                   defaultValue: "\(days) days in a row",
                   comment: "Streak unit under the big number; the number itself is not printed")
        }

        /// "Last fast · 16h 24m" — the eating window's link into the history.
        static func lastFast(_ duration: String) -> String {
            String(localized: "Last fast · \(duration)")
        }

        /// "Best 9 · since 12 March"
        static func best(_ count: Int, _ date: String) -> String {
            String(localized: "Best \(count) · since \(date)", locale: .latinDigits)
        }

        /// "9 fasts · 152h" — the month group's aggregate.
        static func groupMeta(_ count: Int, _ hours: String) -> String {
            String(localized: "\(count) fasts · \(hours)", locale: .latinDigits)
        }

        /// "of 16h" — the goal beside a fast that fell short of it.
        static func ofGoal(_ goal: String) -> String {
            String(localized: "of \(goal)")
        }

        /// "Reached Autophagy"
        static func reached(_ phase: String) -> String {
            String(localized: "Reached \(phase)")
        }

        /// VoiceOver label for the history entry point on the main screen.
        static func entryA11y(_ days: Int) -> String {
            String(localized: "Fasting history, current streak \(days) days")
        }

        /// The same label with no streak to announce — the pill reads "History".
        static var entryA11yNoStreak: String { String(localized: "Fasting history") }
    }

    enum Notification {
        static var goalTitle: String { String(localized: "Fast complete") }
        static var goalBody: String { String(localized: "You reached your goal. Your eating window is open.") }
        static var eatingEndTitle: String { String(localized: "Eating window closed") }
        static var eatingEndBody: String { String(localized: "Time to fast. Start whenever you're ready.") }
    }

    enum Sources {
        static var disclaimerTitle: String { String(localized: "Disclaimer") }
        static var disclaimerBody: String { String(localized: "Disclaimer: This app does not provide medical advice. Please consult a doctor before making any health-related decisions.") }
        static var title: String { String(localized: "Scientific Sources") }
        static var subtitle: String { String(localized: "The research behind each fasting phase.") }
        static var viewStudy: String { String(localized: "View Study") }
        static var source1: String { String(localized: "Glycogen and its metabolism: some new developments and old themes") }
        static var source2: String { String(localized: "Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial") }
        static var source3: String { String(localized: "Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase") }
        static var source4: String { String(localized: "Intermittent Fasting and Metabolic Health") }
    }
}
