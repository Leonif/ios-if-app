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
        static var complete: String { String(localized: "Fast complete. Your eating window is open. Refuel gently.") }
        static var fed: String { String(localized: "Still digesting. Insulin is up and your body is storing the energy from your last meal.") }
        static var sugar: String { String(localized: "Glucose is easing down. Your body is leaning on its glycogen stores for fuel.") }
        static var fat: String { String(localized: "Glycogen is running low. Fat is becoming your main source of energy.") }
        static var ketosis: String { String(localized: "Ketones are climbing. You're well into fat-burning now.") }
        static var autophagy: String { String(localized: "Deep in the fast. Autophagy is recycling what your cells no longer need.") }

        /// "Autophagy begins in 2h 36m"
        static func beginsIn(_ phase: String, _ when: String) -> String {
            String(format: String(localized: "%@ begins in %@"), phase, when)
        }
    }

    enum Timer {
        static var elapsedCaption: String { String(localized: "ELAPSED") }
        static var fastComplete: String { String(localized: "FAST COMPLETE") }
        static var start: String { String(localized: "Start") }
        static var dailyFast: String { String(localized: "Daily fast") }
        static var lastMeal: String { String(localized: "Last meal · ") }
    }

    enum Footer {
        static var started: String { String(localized: "Started") }
        static var elapsed: String { String(localized: "Elapsed") }
        static var endFast: String { String(localized: "End fast") }
        static var fasted: String { String(localized: "Fasted") }
        static var windowOpens: String { String(localized: "Window opens") }
        static var reset: String { String(localized: "Reset") }
        static var startEatingWindow: String { String(localized: "Start eating window") }

        /// "Goal · 16h"
        static func goal(_ hours: String) -> String {
            String(localized: "Goal · \(hours)")
        }
    }

    enum Sheet {
        static var fastingPlan: String { String(localized: "Fasting plan") }
        static var tapToChange: String { String(localized: "Tap to change") }
        static var eatingWindow: String { String(localized: "Eating window") }
        static var done: String { String(localized: "Done") }
        static var whenDidYouEat: String { String(localized: "When did you last eat?") }
        static var backdateHint: String { String(localized: "We'll back-date your fast so the timer stays accurate.") }
        static var chip30Min: String { String(localized: "30 min") }
        static var chip1Hour: String { String(localized: "1 hour") }
        static var chip2Hours: String { String(localized: "2 hours") }
        static var date: String { String(localized: "Date") }
        static var time: String { String(localized: "Time") }
        static var confirm: String { String(localized: "Confirm") }
        static var orSetExact: String { String(localized: "OR SET EXACT") }
        static var fastingSince: String { String(localized: "Fasting since") }
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
        static func daysAgo(_ n: Int) -> String { String(localized: "\(n) days ago") }

        /// "Yesterday 7:00 PM"
        static func yesterdayAt(_ time: String) -> String { String(localized: "Yesterday \(time)") }

        /// "2h 43m in"
        static func noteIn(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %02dm in"), h, m)
        }

        /// "Fast counts from 7:00 PM · 2h 40m in"
        static func fastCountsFrom(_ from: String, _ note: String) -> String {
            String(localized: "Fast counts from \(from) · \(note)")
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

    enum Review {
        static var title: String { String(localized: "Enjoying IF24?") }
        static var subtitle: String { String(localized: "Your review helps us grow.") }
        static var positive: String { String(localized: "Yes, love it") }
        static var dismiss: String { String(localized: "Not now") }
    }

    enum Notification {
        static var goalTitle: String { String(localized: "Fast complete") }
        static var goalBody: String { String(localized: "You reached your goal. Your eating window is open.") }
    }

    enum Sources {
        static var disclaimerTitle: String { String(localized: "Disclaimer") }
        static var disclaimerBody: String { String(localized: "Disclaimer: This app does not provide medical advice. Please consult a doctor before making any health-related decisions.") }
        static var title: String { String(localized: "Scientific Sources") }
        static var viewStudy: String { String(localized: "View Study") }
        static var source1: String { String(localized: "Glycogen and its metabolism: some new developments and old themes") }
        static var source2: String { String(localized: "Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial") }
        static var source3: String { String(localized: "Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase") }
        static var source4: String { String(localized: "Intermittent Fasting and Metabolic Health") }
    }
}
