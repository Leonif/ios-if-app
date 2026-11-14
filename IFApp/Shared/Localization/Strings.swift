//
//  Strings.swift
//  IFApp
//

import Foundation

extension Locale {
    static var latinDigits: Locale {
        var components = Locale.Components(locale: .current)
        components.numberingSystem = Locale.NumberingSystem("latn")
        components.calendar = .gregorian
        return Locale(components: components)
    }
}

extension Date.FormatStyle {
    static var latinDigits: Date.FormatStyle {
        let locale = Locale.latinDigits
        return Date.FormatStyle(locale: locale, calendar: locale.calendar)
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
        static var idle: String { String(localized: "Start whenever you’re ready, or log your last meal to pick up a fast already in progress.") }
        static var complete: String { String(localized: "Fast complete. Your eating window is ready. Refuel gently.") }
        static var windowOpen: String { String(localized: "Fast complete. Your eating window is open. Refuel gently.") }
        static var fed: String {
            String(localized: "Editorial.fed",
                   defaultValue: "Still digesting. Insulin typically runs high now, storing energy from your last meal.")
        }
        static var sugar: String {
            String(localized: "Editorial.sugar",
                   defaultValue: "Glucose typically eases down now. Glycogen stores carry the fuel.")
        }
        static var fat: String {
            String(localized: "Editorial.fat",
                   defaultValue: "Glycogen typically runs low by now. Fat takes over as the main fuel.")
        }
        static var ketosis: String {
            String(localized: "Editorial.ketosis",
                   defaultValue: "Ketones typically climb around this hour. They fuel brain and muscles.")
        }
        static var autophagy: String {
            String(localized: "Editorial.autophagy",
                   defaultValue: "Deep in the fast. Autophagy typically recycles what cells no longer need.")
        }
        static var windowClosed: String { String(localized: "Your eating window has closed. Every minute since already counts - continue your fast whenever you’re ready.") }

        static func goalReached(_ hours: Int) -> String {
            String(format: String(localized: "Editorial.goalReached",
                                  defaultValue: "You’ve reached your %d-hour goal. From here the fast is typically at its deepest."),
                   hours)
        }

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

        static func closesAt(_ time: String) -> String {
            String(localized: "Closes \(time)")
        }

        static func goalOvertime(_ goal: String, _ over: String) -> String {
            String(format: String(localized: "Goal %@ · +%@"), goal, over)
        }

        static var deepAutophagy: String {
            String(localized: "Timer.deepAutophagy", defaultValue: "Deep autophagy")
        }
    }

    enum Footer {
        static var started: String { String(localized: "Started") }
        static var elapsed: String { String(localized: "Elapsed") }
        static var endFast: String { String(localized: "End fast") }
        static var fasted: String { String(localized: "Fasted") }
        static var windowOpens: String { String(localized: "Window opens") }
        static var reset: String { String(localized: "Reset") }
        static var startFast: String { String(localized: "Start fast") }
        static var continueFasting: String { String(localized: "Continue fasting") }
        static var goalStat: String { String(localized: "Goal") }
        static var over: String { String(localized: "Over") }

        static func goal(_ hours: String) -> String {
            String(localized: "Goal · \(hours)")
        }

        static var startEating: String {
            String(localized: "Footer.startEating", defaultValue: "Start eating")
        }

        static var declineWindow: String {
            String(localized: "Footer.declineWindow", defaultValue: "No thanks")
        }

        static var doneEating: String {
            String(localized: "Footer.doneEating", defaultValue: "End eating window")
        }

        static var notNowFast: String {
            String(localized: "Footer.notNowFast", defaultValue: "Not now")
        }

        static func consequenceNearGoal(_ duration: String) -> String {
            String(format: String(localized: "Footer.consequenceNearGoal",
                                  defaultValue: "You fasted %@ — today doesn't count toward your streak."),
                   duration)
        }

        static var consequenceDefault: String {
            String(localized: "Footer.consequenceDefault",
                   defaultValue: "Leaving this screen ends this fast for good.")
        }
    }

    enum Complete {
        static var resumeFast: String { String(localized: "Resume this fast") }
    }

    enum EndFast {
        static var title: String { String(localized: "When did you eat?") }
        static var hint: String { String(localized: "Your eating window starts from this moment.") }

        static var nearGoalTitle: String { String(localized: "End this fast?") }

        static func minutesLeft(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes left to your goal", locale: .latinDigits)
        }

        static func timerRanPast(_ duration: String) -> String {
            String(format: String(localized: "The timer has run %@ past your goal"), duration)
        }

        static var fastEnds: String { String(localized: "Fast ends") }
        static var endNow: String { String(localized: "End now") }
        static var setTheTime: String { String(localized: "Set the time") }
        static var chip1Hour: String { String(localized: "1 h ago") }

        static func chipMinutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago", locale: .latinDigits)
        }

        static func goalEndCaption(_ day: String) -> String {
            String(format: String(localized: "%@ · goal end"), day)
        }

        static var refusalTitle: String { String(localized: "That time is taken") }

        static func refusalReason(_ span: String) -> String {
            String(format: String(localized: "This overlaps a fast you already saved (%@). Pick another time, or open that fast and delete it."), span)
        }

        static func refusalReasonUnavoidable(_ span: String) -> String {
            String(format: String(localized: "This fast overlaps one you already saved (%@). To end it, open that fast and delete it."), span)
        }

        static var pickAnotherTime: String { String(localized: "Pick another time") }
        static var openThatFast: String { String(localized: "Open that fast") }
    }

    enum Reset {
        static var confirmTitle: String { String(localized: "Reset this fast?") }
        static var confirmMessage: String { String(localized: "This discards the current fast and returns to the start.") }
        static var confirmAction: String { String(localized: "Reset fast") }
        static var keepThisFast: String { String(localized: "Keep this fast") }
    }

    enum EndEating {
        static var confirmTitle: String {
            String(localized: "EndEating.confirmTitle", defaultValue: "End your eating window now?")
        }
        static var confirmMessage: String {
            String(localized: "EndEating.confirmMessage",
                   defaultValue: "It closes now instead of at the set time, and you won’t get the closing notification.")
        }
        static var confirmAction: String {
            String(localized: "EndEating.confirmAction", defaultValue: "End window")
        }
        static var keepOpen: String {
            String(localized: "EndEating.keepOpen", defaultValue: "Keep it open")
        }
    }

    enum Sheet {
        static var fastingPlan: String { String(localized: "Fasting plan") }
        static var planSubtitle: String { String(localized: "Pick how long a fast runs. The window starts when you end it.") }
        static var customLength: String { String(localized: "Custom length") }
        static var customCaption: String { String(localized: "From 1 to 23 hours") }
        static var whenDidYouEat: String { String(localized: "When did you last eat?") }
        static var backdateHint: String { String(localized: "We’ll back-date your fast so the timer stays accurate.") }
        static var confirm: String { String(localized: "Confirm") }
        static var orSetExact: String { String(localized: "OR SET EXACT") }
    }

    enum PlanEditor {
        static var confirm: String {
            String(localized: "PlanEditor.confirm", defaultValue: "Done")
        }
    }

    enum Meal {
        static var today: String { String(localized: "Today") }
        static var yesterday: String { String(localized: "Yesterday") }
        static var now: String { String(localized: "Now") }
        static var justNow: String { String(localized: "Just now") }
        static var startingFresh: String { String(localized: "starting fresh") }

        static func daysAgo(_ n: Int) -> String { String(localized: "\(n) days ago", locale: .latinDigits) }

        static func noteIn(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %02dm in"), h, m)
        }

        static func fastCountsFrom(_ from: String, _ note: String) -> String {
            String(localized: "Fast counts from \(from) · \(note)")
        }

        // MARK: - Last-meal picker

        static var chip1h: String { String(localized: "1h", comment: "Meal picker chip: one hour ago") }
        static var chip3h: String { String(localized: "3h", comment: "Meal picker chip: three hours ago") }
        static var chipLastNight: String { String(localized: "Last night") }
        static var setExactTime: String { String(localized: "Set exact time") }

        static var exactTimeDone: String {
            String(localized: "Meal.exactTimeDone", defaultValue: "Done")
        }
        static var scaleLimitNote: String { String(localized: "That’s as far back as we go.") }
        static var windowClosedOverline: String { String(localized: "Eating window closed") }
        static var scaleA11yLabel: String { String(localized: "Time since last meal") }

        static func scaleA11yValue(_ relative: String, _ absolute: String) -> String {
            String(localized: "Meal.scaleA11yValue", defaultValue: "\(relative), \(absolute)")
        }

        static func agoMinutes(_ m: Int) -> String {
            String(format: String(localized: "%dm ago"), m)
        }
        static func agoRelative(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %dm ago"), h, m)
        }
        static func agoDays(_ d: Int, _ h: Int) -> String {
            String(format: String(localized: "%dd %dh ago"), d, h)
        }
        static func todayAt(_ time: String) -> String { String(localized: "Today at \(time)") }
        static func yesterdayAt(_ time: String) -> String { String(localized: "Yesterday at \(time)") }
        static func dateAt(_ date: String, _ time: String) -> String {
            String(localized: "\(date) at \(time)")
        }

        static func scaleTickHours(_ h: Int) -> String {
            String(format: String(localized: "%dh"), h)
        }
        static func scaleTickDays(_ d: Int) -> String {
            String(format: String(localized: "%dd"), d)
        }
    }

    enum Duration {
        static func hm(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %02dm"), h, m)
        }
        static func hmShort(_ h: Int, _ m: Int) -> String {
            String(format: String(localized: "%dh %dm"), h, m)
        }
        static func minutes(_ m: Int) -> String {
            String(format: String(localized: "%dm"), m)
        }
        static func goalHours(_ h: Int) -> String {
            String(format: String(localized: "%dh"), h)
        }
        static func daysShort(_ d: Int) -> String {
            String(format: String(localized: "%dd"), d)
        }
        static func hoursSpelled(_ h: Int) -> String {
            String(localized: "\(h) hours", locale: .latinDigits)
        }
        static func planWindowSuffix(_ window: String) -> String {
            String(format: String(localized: "fast · %@ window"), window)
        }
    }

    enum Streak {
        static func milestoneTitle(_ days: Int) -> String {
            String(localized: "\(days) days in a row", locale: .latinDigits)
        }
        static var milestoneSubtitle: String { String(localized: "You’ve hit your fasting goal every day. Keep the rhythm going.") }
        static var milestoneClose: String { String(localized: "Keep going") }
    }

    enum History {
        static var title: String { String(localized: "History") }
        static var streakOverline: String { String(localized: "Current streak") }
        static var lastStreakOverline: String {
            String(localized: "history.streak.lastOverline",
                   defaultValue: "Last streak",
                   comment: """
                   Overline over the big streak number on the history summary card, in the
                   state where the run has ended. Uppercased in the UI. Hard budget 146pt,
                   keep it to two short words.
                   """)
        }
        static var goalDays: String {
            String(localized: "history.goalDays",
                   defaultValue: "Goal reached",
                   comment: "Label above seven weekday dots. It describes the dots as a result: filled means the fasting goal was reached for the fast dated that day; hollow means it was not reached, not that the day is unfinished.")
        }
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
        static var emptyBackToFast: String { String(localized: "Back to your fast") }
        static var firstNote: String {
            String(localized: "history.streak.firstFast",
                   defaultValue: "First fast logged. A streak counts the days you reach your goal.",
                   comment: """
                   Note on the summary card over the first fasts, under the streak counter.
                   Replaces the old promise that tomorrow starts the streak. States the rule:
                   only a day whose goal was reached counts. Neutral, no blame, no exclamation.
                   """)
        }
        static var savedToHistory: String { String(localized: "Saved to your history") }
        static var export: String { String(localized: "Export") }
        static var exportTitle: String { String(localized: "History.exportTitle") }
        static var exportCaption: String { String(localized: "History.exportCaption") }

        static func daysInARow(_ days: Int) -> String {
            String(localized: "history.streak.unit",
                   defaultValue: "\(days) days in a row",
                   comment: """
                   Streak unit rendered to the RIGHT of the big number in the same HStack
                   (HistorySummaryCard), not under it. counterSpacing is 0 for ja/ko/zh, so in
                   CJK the number and this string render as one solid token - ko renders
                   "5일 연속", ja "5日". The word "streak" itself is carried by the card
                   overline - do not repeat it here.
                   """)
        }

        static func streakEnded(_ days: Int, lastGoalDate: String?) -> String {
            let date = lastGoalDate
                .flatMap(Clock.date(forDayKey:))
                .map(HistoryFormat.sinceDate)
                ?? ""
            return String(localized: "history.streak.ended",
                          defaultValue: "The streak lasted \(days) days. The last goal was reached on \(date). A new one starts with your next completed goal.",
                          locale: .latinDigits,
                          comment: """
                          Sentence on the history summary card under the big number, in the state
                          where the streak has just ended (shown for 7 days after the missed day).
                          The number is the run that was lost; the date is explicitly its final
                          completed goal day, formatted as localized day and month — never call it
                          the day the streak ended, because the break is detected later. Plural
                          categories belong in the catalog. Up to 3 lines at xxLarge in a 299pt
                          slot. No blame, no call to action, no mention of the paid freeze.
                          """)
        }

        static func lastFast(_ duration: String) -> String {
            String(localized: "Last fast · \(duration)")
        }

        static func best(_ count: Int, _ date: String) -> String {
            String(localized: "Best \(count) · since \(date)", locale: .latinDigits)
        }

        static func groupMeta(_ count: Int, _ hours: String) -> String {
            String(localized: "\(count) fasts · \(hours)", locale: .latinDigits)
        }

        static func ofGoal(_ goal: String) -> String {
            String(localized: "of \(goal)")
        }

        static func reached(_ phase: String) -> String {
            String(localized: "Reached \(phase)")
        }

        static func entryA11y(_ days: Int) -> String {
            String(localized: "Fasting history, current streak \(days) days")
        }

        static func entryA11yLastStreak(_ days: Int) -> String {
            String(localized: "history.entry.a11yLastStreak",
                   defaultValue: "Fasting history, last streak \(days) days",
                   comment: """
                   VoiceOver label of the streak pill on the main screen when the run has
                   ended and its number is still shown, drained of accent.
                   """)
        }

        static var entryA11yNoStreak: String { String(localized: "Fasting history") }
    }

    enum Notification {
        static var goalTitle: String { String(localized: "Fast complete") }
        static var goalBody: String { String(localized: "You reached your goal. Your eating window is open.") }
        static var eatingEndTitle: String { String(localized: "Eating window closed") }
        static var eatingEndBody: String { String(localized: "Time to fast. Start whenever you’re ready.") }
    }

    enum Pro {
        static var productName: String { "IF24\u{00A0}Pro" }

        static var lockedDestinationHint: String {
            String(localized: "Pro.lockedDestinationHint",
                   defaultValue: "Opens the IF24\u{00A0}Pro screen")
        }

        static var headline: String { String(localized: "One purchase, for good") }
        static var framingCustom: String { String(localized: "Your plan, your number - any length you want, from one hour to twenty-three.") }
        static var framingProtectedDay: String { String(localized: "A missed day stays a missed day - your streak keeps counting from where it was.") }
        static var framingExport: String {
            String(localized: "Pro.framingExport",
                   defaultValue: "Your record is yours - take the whole history out as a file whenever you want it.",
                   comment: """
                   The framing line under the offer's headline, shown only when the offer was
                   opened from the locked CSV export in History. Sits directly above the
                   benefit list, whose first item is "History as CSV" / "Export every fast you
                   have logged, whenever you like." — so this line must not repeat that
                   wording. Same register and length class as the other two framing lines
                   (Pro.framingCustom, Pro.framingProtectedDay); it wraps freely, no hard
                   budget.
                   """)
        }

        static var benefitCustomTitle: String { String(localized: "Custom length") }
        static var benefitCustomBody: String { String(localized: "Any whole hour, not only the four presets.") }
        static var benefitExportTitle: String { String(localized: "History as CSV") }
        static var benefitExportBody: String { String(localized: "Export every fast you have logged, whenever you like.") }
        static var benefitFreezeTitle: String { String(localized: "Protected day") }
        static var benefitFreezeBody: String { String(localized: "One missed day a month leaves your streak intact.") }

        static var oneTimePurchase: String { String(localized: "One-time purchase") }
        static var wedge: String { String(localized: "No subscription, no account") }
        static var buy: String { String(localized: "Buy") }
        static var confirming: String { String(localized: "Confirming") }
        static var tryAgain: String { String(localized: "Try again") }
        static var proActiveBadge: String { String(localized: "Pro active · one-time purchase") }

        static var restoreShort: String { String(localized: "Restore") }
        static var restoreFull: String { String(localized: "Restore purchases") }
        static var privacyShort: String { String(localized: "Privacy") }
        static var privacyFull: String { String(localized: "Privacy policy") }
        static var close: String { String(localized: "Close") }

        static var failedTitle: String { String(localized: "Purchase not completed") }
        static var failedBodyGeneral: String { String(localized: "Something interrupted it before the payment went through. Nothing will be charged.") }
        static var failedBodyNetwork: String { String(localized: "The purchase could not reach the App\u{00A0}Store. Nothing will be charged - try again online.") }
        static var awaitingTitle: String { String(localized: "Awaiting approval") }
        static var awaitingBody: String { String(localized: "The request went to whoever approves your purchases. Pro switches on the moment they approve it - nothing will be charged before that, and everything you already use stays exactly as it is.") }
        static var unverifiedTitle: String { String(localized: "Purchases not checked yet") }
        static var unverifiedBody: String { String(localized: "Restore first - if Pro is on this Apple\u{00A0}Account it comes straight back.") }
        static var restoredTitle: String { String(localized: "Purchases restored") }
        static var restoredBody: String { String(localized: "Pro is active on this device. Everything below is open now.") }
        static var purchasedTitle: String { String(localized: "IF24 Pro is yours") }
        static var approvedTitle: String { String(localized: "Purchase approved") }
        static func purchasedBody(_ displayPrice: String) -> String {
            String(format: String(localized: "Paid %@. One time - nothing renews, nothing to cancel."),
                   paidPrice(displayPrice))
        }
        static var purchasedBodyNoPrice: String {
            String(localized: "The purchase went through. The amount is on your App\u{00A0}Store receipt.")
        }
        private static func paidPrice(_ displayPrice: String) -> String {
            BidiText.isolate(displayPrice.replacingOccurrences(of: " ", with: "\u{00A0}"))
        }
        static var restoredDone: String {
            String(localized: "Pro.restoredDone", defaultValue: "Done")
        }
        static var nothingToRestore: String { String(localized: "No purchases to restore") }

        static var statusInactive: String { String(localized: "Inactive") }
        static var statusActive: String { String(localized: "Active") }
        static var statusAwaiting: String { String(localized: "Awaiting approval") }
        static var statusUnverified: String { String(localized: "Not checked yet") }
        static var sectionFooter: String { String(localized: "Restoring works on any device signed in to the same Apple\u{00A0}Account.") }

        static var revokedTitle: String { String(localized: "IF24\u{00A0}Pro is no longer active") }
        static var revokedBody: String { String(localized: "Your history stays as it is.") }
        static var goalChangedTitle: String { String(localized: "Your goal changed") }
        static func goalChangedBody(_ goal: String) -> String {
            String(format: String(localized: "Custom lengths need IF24\u{00A0}Pro, so your plan is %@ from now on."), goal)
        }
    }

    enum About {
        static var title: String { String(localized: "About IF24") }
        static var privacyFooter: String { String(localized: "No IF24 account, no sign-in - IF24 never asks who you are. Your history is kept on this device; how long your fasts run is sent as usage data.") }
        static var medicalNote: String {
            String(localized: "About.medicalNote",
                   defaultValue: "IF24 shows estimated phases, not measurements of your body. It is not a medical device and does not give medical advice. Talk to a doctor before changing how you eat - especially if you are pregnant, on medication, managing a condition such as diabetes, have a history of disordered eating, or are under 18.")
        }
    }

    enum Sources {
        static var title: String { String(localized: "Scientific Sources") }
    }
}
