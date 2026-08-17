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
        static var idle: String { String(localized: "Start whenever you’re ready, or log your last meal to pick up a fast already in progress.") }
        static var complete: String { String(localized: "Fast complete. Your eating window is ready. Refuel gently.") }
        static var windowOpen: String { String(localized: "Fast complete. Your eating window is open. Refuel gently.") }
        static var fed: String { String(localized: "Still digesting. Insulin is up and your body is storing the energy from your last meal.") }
        static var sugar: String { String(localized: "Glucose is easing down. Your body is leaning on its glycogen stores for fuel.") }
        static var fat: String { String(localized: "Glycogen is running low. Fat is becoming your main source of energy.") }
        static var ketosis: String { String(localized: "Ketones are climbing. You’re well into fat-burning now.") }
        static var autophagy: String { String(localized: "Deep in the fast. Autophagy is recycling what your cells no longer need.") }
        static var windowClosed: String { String(localized: "Your eating window has closed. Every minute since already counts - continue your fast whenever you’re ready.") }

        /// Editorial shown once the goal is reached (overtime). `hours` = plan goal in hours.
        static func goalReached(_ hours: Int) -> String {
            String(format: String(localized: "You’ve reached your %d-hour goal. Every minute now is deeper autophagy."), hours)
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
        static var startFast: String { String(localized: "Start fast") }
        static var continueFasting: String { String(localized: "Continue fasting") }
        static var goalStat: String { String(localized: "Goal") }
        static var over: String { String(localized: "Over") }

        /// "Goal · 16h"
        static func goal(_ hours: String) -> String {
            String(localized: "Goal · \(hours)")
        }

        // The primary of the `.complete` card, and the three footer secondaries — each
        // on its own key now. A footer secondary is defined by the primary beside it,
        // and one generic verb could not be right next to "Start eating", "Start fast"
        // and "Continue fasting" at once.
        //
        // Named keys, not English source text — the exception `history.streak.unit`
        // already makes. Keyed by their English text, `Done` here would land on the
        // plan sheet's button and take the paywall's with it.

        /// The `.complete` primary: opens the eating window. English drops the word
        /// "window" the other nine locales had already dropped — the stat directly
        /// above the button says WINDOW OPENS, so the card names it once either way.
        static var startEating: String {
            String(localized: "Footer.startEating", defaultValue: "Start eating")
        }

        /// `.complete`, beside "Start eating": declines the window. Not a postponement —
        /// `.complete` has no timeout, so the offer stands until the user acts, and this
        /// tap is what puts it out of reach for the rest of the cycle.
        static var declineWindow: String {
            String(localized: "Footer.declineWindow", defaultValue: "No thanks")
        }

        /// `.eating`, beside "Start fast": ends the eating window early. A real activity
        /// finished, not a sheet dismissed — which is why it is not the plan sheet's key.
        static var doneEating: String {
            String(localized: "Footer.doneEating", defaultValue: "Done")
        }

        /// `.eatingOver`, beside "Continue fasting": the window has already closed, so
        /// this defers the next fast rather than skipping anything. "Not now" is true
        /// here — a fast can be started from idle at any time.
        static var notNowFast: String {
            String(localized: "Footer.notNowFast", defaultValue: "Not now")
        }
    }

    enum Complete {
        /// The undo on the result screen. It promises the *fast* back, not the record
        /// gone — "Undo" would be ambiguous between the two, and the determiner is
        /// load-bearing: bare "Resume fast" reads as resuming fasting in general.
        /// Same family as `Reset this fast?` / `Delete this fast?` below.
        static var resumeFast: String { String(localized: "Resume this fast") }
    }

    /// The end-of-fast correction sheet. Its own namespace rather than more of
    /// `Sheet`, because the two sheets ask about opposite ends of the same fast and
    /// the distinction is carried by a single adverb in English ("last") that other
    /// languages have to spell out on the verb — a shared key would be true in
    /// English and undifferentiated everywhere else.
    enum EndFast {
        /// The header of the picker states. Deliberately not `Sheet.whenDidYouEat`
        /// ("When did you last eat?"): at this moment the meal that ended the fast
        /// *is* the last one, so the old line is not false — it just stops
        /// distinguishing the two questions.
        static var title: String { String(localized: "When did you eat?") }
        static var hint: String { String(localized: "Your eating window starts from this moment.") }

        /// The near-goal header. It asks rather than states, because at this distance
        /// from the goal the question is genuinely open.
        static var nearGoalTitle: String { String(localized: "End this fast?") }

        /// The consequence line, in whole minutes and never a duration format. Arabic
        /// agrees the numeral across six CLDR classes and four of them are reachable
        /// under a 15-minute threshold, so "0 h 10" is not expressible there at all.
        /// The subject is the time, never the person: no encouragement in this line,
        /// in any locale.
        static func minutesLeft(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes left to your goal", locale: .latinDigits)
        }

        /// The overtime line. The subject is the app's own instrument — the timer —
        /// and never the person's fast: the line shows precisely when the app is
        /// *assuming* they have already eaten, so asserting their fast is running
        /// asserts something it does not know.
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

        /// "Yesterday · goal end" — the caption under the exact-time value when it is
        /// still sitting where the sheet put it.
        static func goalEndCaption(_ day: String) -> String {
            String(format: String(localized: "%@ · goal end"), day)
        }

        /// The refusal's own header. It does not reuse the picker's: over a body that
        /// is no longer a picker, "When did you eat?" describes nothing on screen.
        static var refusalTitle: String { String(localized: "That time is taken") }

        /// The refusal names the fast in the way — a refusal that does not say what
        /// is blocking it is the silent "no" this state replaces.
        static func refusalReason(_ span: String) -> String {
            String(format: String(localized: "This overlaps a fast you already saved (%@). Pick another time, or open that fast and delete it."), span)
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

    enum Sheet {
        static var fastingPlan: String { String(localized: "Fasting plan") }
        static var planSubtitle: String { String(localized: "Pick how long a fast runs. The window starts when you end it.") }
        static var customLength: String { String(localized: "Custom length") }
        static var customCaption: String { String(localized: "From 1 to 23 hours") }
        static var whenDidYouEat: String { String(localized: "When did you last eat?") }
        static var backdateHint: String { String(localized: "We’ll back-date your fast so the timer stays accurate.") }
        static var chip30Min: String { String(localized: "30 min") }
        static var chip1Hour: String { String(localized: "1 hour") }
        static var chip2Hours: String { String(localized: "2 hours") }
        static var date: String { String(localized: "Date") }
        static var time: String { String(localized: "Time") }
        static var confirm: String { String(localized: "Confirm") }
        static var orSetExact: String { String(localized: "OR SET EXACT") }
        static var fastingSince: String { String(localized: "Fasting since") }
    }

    /// The plan editor's own strings. It shares the rest of its copy with `Sheet`; this
    /// one button is separate because it used to share a key with the paywall too, and
    /// the two say the same English word for opposite reasons.
    enum PlanEditor {
        /// Applies the plan just chosen. It confirms a choice, so it keeps the Done
        /// lexeme in every locale — never the OK one, which acknowledges rather than
        /// decides. Split off the shared `Done`; the other half is `Pro.restoredDone`.
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

        /// "2 days ago" (locale-aware plural)
        static func daysAgo(_ n: Int) -> String { String(localized: "\(n) days ago", locale: .latinDigits) }

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
        /// "17 hours" — the hour picker's rows, spelled out. Plural categories live
        /// in the catalog, never as an `h == 1` here.
        static func hoursSpelled(_ h: Int) -> String {
            String(localized: "\(h) hours", locale: .latinDigits)
        }
        /// "fast · 8h window" — the trailing half of the plan sheet's value line.
        /// The leading number is drawn separately, in display type.
        static func planWindowSuffix(_ window: String) -> String {
            String(format: String(localized: "fast · %@ window"), window)
        }
    }

    enum Streak {
        /// Milestone card title, e.g. "7 days in a row".
        static func milestoneTitle(_ days: Int) -> String {
            String(localized: "\(days) days in a row", locale: .latinDigits)
        }
        static var milestoneSubtitle: String { String(localized: "You’ve hit your fasting goal every day. Keep the rhythm going.") }
        static var milestoneClose: String { String(localized: "Keep going") }
    }

    enum History {
        static var title: String { String(localized: "History") }
        static var streakOverline: String { String(localized: "Current streak") }
        /// The same overline once the run is over: it renames the number as past, and
        /// carries no verdict — the sentence under the number says what happened. The
        /// short class deliberately ("Streak ended" fills 100% of the slot in Ukrainian,
        /// with no slack for a retranslation).
        static var lastStreakOverline: String {
            String(localized: "history.streak.lastOverline",
                   defaultValue: "Last streak",
                   comment: """
                   Overline over the big streak number on the history summary card, in the
                   state where the run has ended. Uppercased in the UI. Hard budget 146pt,
                   keep it to two short words.
                   """)
        }
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
        /// The empty state's action while a fast is running. It names the destination
        /// rather than the direction — the nav chevron already means "back", and a
        /// second "Back" would read as two different ways out.
        ///
        /// English source only for now: `loc` is translating it, and until the table
        /// lands the other nine locales fall back to this.
        static var emptyBackToFast: String { String(localized: "Back to your fast") }
        /// The note under the counter on the first fasts. It states the *rule* rather
        /// than the outcome: the old copy ("First one saved. Finish tomorrow's fast and
        /// your streak begins.") promised the day was banked, and it showed after a fast
        /// that fell short of the goal too — where nothing was banked at all (F-2). A
        /// streak day is a goal reached, and that is the one thing worth saying to
        /// someone who has not built one yet. No reproach: it never says what went wrong.
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
        /// The export affordance in the history nav row. The control is the system
        /// share glyph and carries no caption, so this is its VoiceOver label — and
        /// the word is `Export`, without the `CSV` token: the format is named once,
        /// in the offer's benefit title.
        static var export: String { String(localized: "Export") }

        /// Streak unit beside the big number. The number is drawn separately (display
        /// type), so the catalog's plural variants carry the word alone — the CLDR
        /// categories live there, never as a `days == 1` here.
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

        /// The sentence under the counter once the run has ended: it names what the
        /// number now is, and how the next one starts. The pill shows the lost number;
        /// this is the only place that says out loud that it ended. Without reproach and
        /// without a sell — the way back is a goal reached, not a purchase.
        static func streakEnded(_ days: Int) -> String {
            String(localized: "history.streak.ended",
                   defaultValue: "That streak ended at \(days) days. The next one starts with your next completed goal.",
                   locale: .latinDigits,
                   comment: """
                   Sentence on the history summary card under the big number, in the state
                   where the streak has just ended (shown for 7 days after the missed day).
                   The number is the run that was lost. Plural categories belong in the
                   catalog. Up to 3 lines at xxLarge in a 299pt slot. No blame, no call to
                   action, no mention of the paid freeze.
                   """)
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

        /// The label while the lost run is still on the pill. VoiceOver gets the word
        /// the pill is not allowed to spend width on — "last", not "current" — so the
        /// number is not heard as a run still going.
        static func entryA11yLastStreak(_ days: Int) -> String {
            String(localized: "history.entry.a11yLastStreak",
                   defaultValue: "Fasting history, last streak \(days) days",
                   comment: """
                   VoiceOver label of the streak pill on the main screen when the run has
                   ended and its number is still shown, drained of accent.
                   """)
        }

        /// The same label with no streak to announce — the pill carries the history
        /// glyph and no number at all.
        static var entryA11yNoStreak: String { String(localized: "Fasting history") }
    }

    enum Notification {
        static var goalTitle: String { String(localized: "Fast complete") }
        static var goalBody: String { String(localized: "You reached your goal. Your eating window is open.") }
        static var eatingEndTitle: String { String(localized: "Eating window closed") }
        static var eatingEndBody: String { String(localized: "Time to fast. Start whenever you’re ready.") }
    }

    /// The paid tier: the offer screen, the Pro section of the About sheet, and the
    /// two one-time notices that follow the entitlement going away.
    ///
    /// The product name is a literal everywhere it appears and is never templated —
    /// in Korean the particle that follows it is chosen by its pronunciation, which
    /// stops being decidable the moment the token becomes a `%@`.
    enum Pro {
        static var productName: String { "IF24\u{00A0}Pro" }

        /// The VoiceOver hint on any control the offer gates: the locked export in
        /// History, and the plan editor's confirm on the branch where the tap opens the
        /// offer instead of applying the plan. It says where the tap leads, not what it
        /// does — the label of each control stays truthful and unchanged.
        ///
        /// A hint is never the only carrier: the user can switch hints off, so every
        /// gated control also names the tier in a channel he cannot suppress.
        ///
        /// "the … screen" is load-bearing, not padding: after "opens", a bare product
        /// name lands in the "application" class in every language Apple ships, so a
        /// blind user hears "launches the separate IF24 Pro app", concludes it is not
        /// installed, and does not tap. The non-breaking space inside the token is the
        /// catalog's rule for it — all 32 occurrences carry it.
        static var lockedDestinationHint: String {
            String(localized: "Pro.lockedDestinationHint",
                   defaultValue: "Opens the IF24\u{00A0}Pro screen")
        }

        // Offer — headline and the framing line under it. The framing line belongs
        // to whichever benefit leads the list, so it changes with the entry point.
        static var headline: String { String(localized: "One purchase, for good") }
        static var framingCustom: String { String(localized: "Your plan, your number - any length you want, from one hour to twenty-three.") }
        static var framingProtectedDay: String { String(localized: "A missed day stays a missed day - your streak keeps counting from where it was.") }

        // Offer — the three benefits.
        static var benefitCustomTitle: String { String(localized: "Custom length") }
        static var benefitCustomBody: String { String(localized: "Any whole hour, not only the four presets.") }
        static var benefitExportTitle: String { String(localized: "History as CSV") }
        static var benefitExportBody: String { String(localized: "Export every fast you have logged, whenever you like.") }
        static var benefitFreezeTitle: String { String(localized: "Protected day") }
        static var benefitFreezeBody: String { String(localized: "One missed day a month leaves your streak intact.") }

        // Offer — price block.
        static var oneTimePurchase: String { String(localized: "One-time purchase") }
        /// The wedge, word for word as it stands in the store's promotional text.
        static var wedge: String { String(localized: "No subscription, no account") }
        static var buy: String { String(localized: "Buy") }
        static var confirming: String { String(localized: "Confirming") }
        static var tryAgain: String { String(localized: "Try again") }
        static var proActiveBadge: String { String(localized: "Pro active · one-time purchase") }

        /// Two keys with the same meaning: the short one is a link in the service
        /// block, paired with Privacy; the full one is a row and a button. They read
        /// alike in eight locales and differently in English and Arabic, which is
        /// exactly what the split exists for — merging them would force the other
        /// eight to drop a grammatically required object.
        static var restoreShort: String { String(localized: "Restore") }
        static var restoreFull: String { String(localized: "Restore purchases") }
        static var privacyShort: String { String(localized: "Privacy") }
        static var privacyFull: String { String(localized: "Privacy policy") }
        static var close: String { String(localized: "Close") }

        // Offer — states S3…S6.
        static var failedTitle: String { String(localized: "Purchase not completed") }
        static var failedBodyGeneral: String { String(localized: "Something interrupted it before the payment went through. Nothing will be charged.") }
        static var failedBodyNetwork: String { String(localized: "The purchase could not reach the App\u{00A0}Store. Nothing will be charged - try again online.") }
        static var awaitingTitle: String { String(localized: "Awaiting approval") }
        static var awaitingBody: String { String(localized: "The request went to whoever approves your purchases. Pro switches on the moment they approve it - nothing will be charged before that, and everything you already use stays exactly as it is.") }
        static var unverifiedTitle: String { String(localized: "Purchases not checked yet") }
        static var unverifiedBody: String { String(localized: "Restore first - if Pro is on this Apple\u{00A0}Account it comes straight back.") }
        static var restoredTitle: String { String(localized: "Purchases restored") }
        static var restoredBody: String { String(localized: "Pro is active on this device. Everything below is open now.") }
        /// The primary of the restored panel — the same full-width slot that carries
        /// Buy and Restore in the other states, on a screen that still has its title,
        /// its badge and its check-marks. That is a result panel and not an alert, so
        /// the locale takes its Done lexeme and not its OK one. Split off the shared
        /// `Done`; the other half is `PlanEditor.confirm`.
        static var restoredDone: String {
            String(localized: "Pro.restoredDone", defaultValue: "Done")
        }
        /// Transient answer to a Restore that found nothing. Not a failure and not a
        /// state of its own: the store answered, the answer was empty. No full stop
        /// in any of the ten locales.
        static var nothingToRestore: String { String(localized: "No purchases to restore") }

        // About IF24 — the Pro row's four statuses.
        //
        // The axis is the state of the entitlement, never the tier, the purchase or
        // the price. `inactive` is empty in Japanese by decision, not by omission:
        // the right-hand column of a settings row reads there as "the option you
        // picked", and every attested candidate said something false.
        static var statusInactive: String { String(localized: "Inactive") }
        static var statusActive: String { String(localized: "Active") }
        static var statusAwaiting: String { String(localized: "Awaiting approval") }
        static var statusUnverified: String { String(localized: "Not checked yet") }
        static var sectionFooter: String { String(localized: "Restoring works on any device signed in to the same Apple\u{00A0}Account.") }

        // Notices — edge 6 and edge 17. One sheet, two moments.
        static var revokedTitle: String { String(localized: "IF24\u{00A0}Pro is no longer active") }
        static var revokedBody: String { String(localized: "Your history stays as it is.") }
        /// Edge 17 / PW-10. Keyed by its own English text like every other string
        /// here, and deliberately so: while a key had an empty default, the catalog
        /// compiler dropped the entry, Foundation handed the key back verbatim, and
        /// the sheet rendered `pro.notice.goalChanged.title` on screen (PW-7). With
        /// the English source as the key that failure cannot be built.
        static var goalChangedTitle: String { String(localized: "Your goal changed") }
        /// `%@` is the spelled-out fallback goal ("16 hours") — the vocabulary the
        /// custom length was set in, so it compares against the 17 just lost without
        /// arithmetic.
        static func goalChangedBody(_ goal: String) -> String {
            String(format: String(localized: "Custom lengths need IF24\u{00A0}Pro, so your plan is %@ from now on."), goal)
        }
    }

    enum About {
        static var title: String { String(localized: "About IF24") }
        static var privacyFooter: String { String(localized: "No IF24 account, no sign-in - IF24 never asks who you are. Your history is kept on this device; how long your fasts run is sent as usage data.") }
        /// Closes the science section rather than sitting under a commercial row.
        static var medicalNote: String { String(localized: "The fasting phases IF24 shows are estimates based on typical timing, not a measurement of your body. IF24 is not a medical device and does not give medical advice. If you are pregnant, managing diabetes, or taking medication with food, talk to a clinician before changing how you eat.") }
    }

    enum Sources {
        static var title: String { String(localized: "Scientific Sources") }
        static var source1: String { String(localized: "Glycogen and its metabolism: some new developments and old themes") }
        static var source2: String { String(localized: "Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial") }
        static var source3: String { String(localized: "Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase") }
        static var source4: String { String(localized: "Intermittent Fasting and Metabolic Health") }
    }
}
