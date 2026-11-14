# IFAppTests - notes for agents

Why the unit tests check what they check, and why their fixtures are shaped the way they are. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

Codes used below: T1' is the paywall spec's automatic-offer trigger and S1-S6 the offer screen's states; "edge N" is the paywall spec's numbered edge case (see `IFApp/Features/pro/NOTES.md`).

## AnalyticsEventTests.swift

- `AnalyticsEventTests` — guards the one property of the event catalog that cannot be seen from inside the app: whether a parameter arrives in GA4 as text. A number logged as a number lands in the numeric field, a custom dimension reads the string field, and the report comes back `(not set)` — silently, for as long as nobody runs the breakdown.
- `AnalyticsEventTests.catalog` — one sample per case of `AnalyticsEvent`, written out by hand because the enum carries associated values and cannot be `CaseIterable`. A new event is therefore not caught automatically; `testCatalogIsFullyCovered` is what makes forgetting it loud.
- `AnalyticsEventTests.numericOnPurpose` — the parameters that are numbers on purpose. `duration_seconds` is the raw quantity behind a custom metric (average fast length), and a metric reads the numeric field — text would break it. Nothing else belongs here: `backdated` is a string — it reflects the person's answer, not a value the sheet seeded, so it reads as a dimension.
- `AnalyticsEventTests.testNumbersAreZeroPaddedToASortableWidth` — `planSelected` — `goal_hours` starts life as an `Int` in the plan editor and as a `Double` in `fastStarted`; both must reach GA4 as the same token, or one dimension carries two vocabularies.
- `AnalyticsEventTests.testNumbersAreZeroPaddedToASortableWidth` — `sourceArticleOpened` — the paper's catalog index is padded like every other numeric dimension: the four papers are read as a distribution, and a distribution is sorted by its dimension.
- `AnalyticsEventTests.testCatalogIsFullyCovered` — every event name appears exactly once, so a case added to the enum without a sample shows up as a count mismatch rather than as a parameter nobody ever type-checked.

## AnalyticsTriggerTests.swift

- `AnalyticsTriggerTests` — the `trigger` parameter is what the paid release is read by: how many people came into the offer through each door, and how the home-screen door compares with the permanent ones. That comparison only works while every value means one thing: the fallback for "no offer was open" is `unknown`, and `manual` keeps meaning a permanent entry the user went looking for.
- `AnalyticsTriggerTests.RepoSpy` — only the parameters matter here; the events' own shape is `AnalyticsEventTests`' business.
- `AnalyticsTriggerTests.testRestoreFailedWithNoOfferOpenReportsUnknown` — restore is offered in two places, and the one in About IF24 is not behind the offer: no `offerOpened` precedes it, so neither the state nor the middleware's pre-reduce snapshot holds an entry point. Filed under `manual`, such a restore would pad the column the home door is measured against with events that are not entries at all.
- `AnalyticsTriggerTests.testOfferOpenedFromAPermanentEntryStillReportsManual` — the other half: `manual` is not retired, it keeps its own meaning. The state passed is post-reduce, which is what a middleware sees — the reducer has already recorded the door.
- `AnalyticsTriggerTests.testTheLockedExportReportsItsOwnDoor` — the offer chooses its lead benefit off the trigger, so the export lock reporting `manual` would open an offer led by the wrong benefit. Asserted against the literal `"history_export"` because the raw string is a GA4 dimension and a rename compiles in silence.
- `AnalyticsTriggerTests.testTriggerVocabularyIsFixed` — the set is what the release is read by; a case added without a value here is a column nobody defined.

## CompleteStatePersistenceTests.swift

- `CompleteStatePersistenceTests` — the result screen ("complete": fast ended, eating window not yet opened) has to survive iOS unloading the app on it. It is carried entirely by `stagedElapsed` and `fastEndTimestamp`; if they are not stored, a cold start there relaunches into idle and the eating window — and its closing push — never comes. The tests pin both halves: the repository keeps the two values, and the reducer clears them on every way off the result screen.
- `CompleteStatePersistenceTests.testMissingKeysReadAsNothingEnded` — installs from before 1.5.2 have neither key. Absent must read as "nothing ended", or an update would put every idle install on a result screen.
- `CompleteStatePersistenceTests.testResetPersistedOverAnEndingRelaunchesIdle` — the stored zeroes must overwrite the stored ending rather than leave it behind.
- `CompleteStatePersistenceTests.restored(end:)` — a 16:8 fast confirmed to have ended at `end`: its window would close 8h later, and the result screen is held for 24h past that — hence `horizon` = 8h + 24h.
- `CompleteStatePersistenceTests.testResultScreenFallsToIdleAtTheHorizon` — at the horizon exactly it goes: the same `>=` the closed-window screen uses.
- `CompleteStatePersistenceTests.testHorizonFollowsThePlansWindow` — the window length is the plan's: an 18:6 ending lapses two hours sooner.
- `CompleteStatePersistenceTests.testOnlyTheResultScreenIsAged` — a running fast and an open window are not touched however old their numbers look.
- `CompleteStatePersistenceTests.testEndingWithoutAnAnchorIsCleared` — ended with no confirmed moment: nothing to measure from, so it is not kept.
- `CompleteStatePersistenceTests.testClosedWindowHorizonBoundary` — the closed-window screen and the result screen share one horizon.
- `CompleteStatePersistenceTests.testLapsedEndingLandsOnTheSameIdleAsReset` — one definition of idle: a lapsed result screen dropped at launch lands on exactly the state `.reset` leaves, including the window fields. The stray `eatingStartTimestamp = 1_234` is a value only `withoutCycle` clears, so a second, partial copy of the idle rule would leave it behind and fail here.

## DateFormatStyleTests.swift

- `DateFormatStyleTests` — `Locale.latinDigits` pins Western digits and the Gregorian calendar, and every `DateFormatter` gets both by taking that locale. A `Date.FormatStyle` does not: its calendar is a separate initialiser argument with its own default, so `Date.FormatStyle(locale: .latinDigits)` pins the digits and leaves the calendar on the device's. On an Arabic device that is the Islamic calendar, and the Sunnah list would print Hijri dates for a schedule counted in Gregorian days.
- `DateFormatStyleTests.testLocaleAloneDoesNotCarryTheCalendarIntoAFormatStyle` — the trap itself, asserted so it cannot come back unnoticed: passing only `locale:` leaves the calendar on `.autoupdatingCurrent`, whatever the locale's own calendar is.
- `DateFormatStyleTests.testUpcomingDateShapeRendersAGregorianYearOnAnArabicLocale` — the Sunnah list's own shape, built the way `Locale.latinDigits` builds itself but on an explicit `ar_SA` base, so the assertion does not depend on the test host's locale. The instant 2026-09-14T12:00:00Z is 2 Rabi al-Thani 1448 on Umm al-Qura, so a Hijri leak shows up as `1448`.

## EndEatingConfirmTests.swift

- `EndEatingConfirmTests` — ending an open eating window early goes through a confirmation whose open flag lives in the store, like `resetConfirmOpen`. The tests pin that opening it ends nothing and that the window survives until the confirm itself.

## FastHistoryRepositoryTests.swift

- `FastHistoryRepositoryTests` — every case runs against a fresh temp directory (`FastHistoryRepository(directory:)`), never the test host's Documents, which is shared between runs and would make one test's leftovers the next test's input. Covers the quarantine of unreadable history files end to end, the `schemaVersion` read-only mode and the `history_load_failed` reasons.
- `FastHistoryRepositoryTests.reported` — the failure reports are taken through the same closure the app wires to analytics in `AppDependencies`, so counting on it is counting the events GA4 would receive.
- `FastHistoryRepositoryTests.writeEnvelope(schemaVersion:records:)` — written by hand so the version can be one this build does not have; `JSONEncoder` on `Envelope` would always stamp the current one.
- `FastHistoryRepositoryTests.testAppendRoundTripsThroughDisk` — read back through a second instance, so the records come off disk, not out of an in-memory cache.
- `FastHistoryRepositoryTests.testCorruptFixtureFailsToDecode` — pins the `-seedHistoryCorrupt` fixture: its bytes really are undecodable. A fixture edited into something that parses would make the seed look useful while testing nothing — and every quarantine case here starts from it.
- `FastHistoryRepositoryTests.testAppendAfterCorruptFileKeepsTheOldBytesInQuarantine` — the case the guard exists for: an append over an undecodable file must not put one fresh record where the whole history had been. The old bytes stay next to it, byte for byte, and can be pulled out of the container.
- `FastHistoryRepositoryTests.testFurtherWritesLeaveTheQuarantinedCopyAlone` — the quarantined copy is evidence, not a working file: once set aside it is never touched again by ordinary use.
- `FastHistoryRepositoryTests.testQuarantineKeepsAtMostThreeCopies` — a repeating failure must not fill the container one launch at a time.
- `FastHistoryRepositoryTests.testEmptyFileIsNotQuarantined` — an empty file is what an interrupted first write leaves; there are no records under it, so filing it away would only archive emptiness.
- `FastHistoryRepositoryTests.testReplaceAllQuarantinesBeforeOverwriting` — `replaceAll` is the one write that discards what it reads (wiping or seeding the history). It still has to read first, or it would be the remaining path that destroys unreadable bytes silently.
- `FastHistoryRepositoryTests.testFutureSchemaReturnsRecordsAndRefusesToWrite` — a file from a newer build: readable records come back, nothing goes in. Writing would put them back in today's shape, which is how a TestFlight downgrade would quietly cost someone whatever the newer format added.
- `FastHistoryRepositoryTests.testFutureSchemaWithUnreadableRecordsIsNotQuarantined` — decides where the version read goes. Records this build cannot parse fail the envelope decode, and a decode failure is what quarantine answers — so reading the version second would file away an intact history the newer build is still using. The version has to be read first.
- `FastHistoryRepositoryTests.testWipeFileClearsAFutureSchemaFileThatReplaceAllRefuses` — the Maestro suite's baseline wipe cannot be `replaceAll([])`: a flow that seeds a future-schema file (`-seedHistoryFutureSchema`) leaves the guard closed for the whole container, and every later flow's reset would silently keep its record. `wipeFile` is the hook that overrules the guard; after it the ordinary seeding path works again because the file is current-schema.
- `FastHistoryRepositoryTests.testWipeFileStillQuarantinesUndecodableBytes` — the hook reads before it writes, so it does not cost the quarantine: bytes that would have been filed away on an ordinary launch still are, and the failure is still reported.
- `FastHistoryRepositoryTests.testEveryReadOfANewerFileReports` — every read reports, deliberately: a `future_schema` on launch and again on the next write attempt is what tells a downgrade apart from a one-off.
- `FastHistoryRepositoryTests.testUnreadableFileIsReportedAsUnreadable` — bytes that cannot be read at all, as opposed to bytes that do not decode; they go into quarantine the same way and differ only in what is reported. Skipped when the runner can read a file with no permissions at all, since the case cannot be produced there.
- `FastHistoryRepositoryTests.testUnmovableFileReportsQuarantineFailedAndStopsWriting` — unreadable and immovable: nothing is written from here on, because the only copy of the history is still where it was and an append would be what finally destroys it. Skipped when the runner can write into a locked directory; the `defer` restores the permissions so the temp directory can be removed.

## HistoryStatsTests.swift

- `HistoryStatsTests` — the summary card's beginner note must not greet a user who carries a streak from an older version as a first-timer: the streak counter can know days the history has never recorded, so the rule reads the counter as well as the records. The first-note matrix pins that rule.
- `HistoryStatsTests.testFirstNoteHiddenWhenStreakOutrunsTheRecords` — the defect itself: one record, a carried-over streak of four. The counter knows days the history has never heard of.
- `HistoryStatsTests.testFirstNoteHiddenWhenTheCarriedStreakHasLapsed` — a lapsed carry-over streak displays as 0 and its owner is still not a beginner; the rule reads the raw counter for exactly this case.
- `HistoryStatsTests.testFirstNoteShownForAFirstGoalDay` — streak of one, one record: nothing contradicts anything, and this is the path the copy was written for, so the fix must not take it away.
- `HistoryStatsTests.testFirstNoteShownWithNoHistoryAndNoStreak` — the card is not shown at zero records, but the rule should not depend on that; it answers for the empty case too.
- `HistoryStatsTests.testMonthGroupIdIsTheGregorianMonth` — the month a record is filed under is a Gregorian month whatever calendar the device runs on. With `Calendar.current` an Arabic device groups by Hijri months, and September records end up under an August header.
- `HistoryStatsTests.testMonthGroupDateIsTheFirstDayOfTheGregorianMonth` — the date behind the header is what `HistoryFormat.monthTitle` formats; the first day of the Hijri month containing 11 September 2026 falls in August, which is the step the wrong calendar breaks.
- `HistoryStatsTests.testRecordsSplitOnGregorianMonthBoundaries` — Hijri buckets cut the same records in different places, so the group count is part of the claim.
- `HistoryStatsTests.testLastSevenDaysCarryDatesOldestToToday` — the seven-dot strip is a calendar map: each dot carries its day so the UI can label Monday through Sunday.
- `HistoryStatsTests.testGoalDotUsesTheHistoryRowsStartDayForAnOvernightFast` — a Tuesday-evening fast reaches a 16-hour goal on Wednesday, but its history row is filed and labelled Tuesday; the dot must follow the row, or two parts of one screen contradict each other. The 19:25 start and 18h17m length put the goal past midnight on purpose.
- `HistoryStatsTests.record(duration:)` — fixed start, because the totals care only how long a fast ran, not when.
- `HistoryStatsTests.testTotalNeverRendersBelowTheLongestFastItContains` — the card prints TOTAL and LONGEST side by side; a sum truncated to whole hours can print below the single fast it is made of (one 16h 01m fast reading "TOTAL 16h · LONGEST 16h 01m"). Asserted on the rendered strings, not the numbers: the numbers agree either way, the two granularities are what can disagree.

## MealPickerTests.swift

- `MealPickerTests` — guards the property the last-meal picker exists to have: the answer means the same thing a minute later as when it was given. The state stores the distance (`minutesAgo`), not the moment: a stored "today, 23:00" re-derived after midnight lies in the future, the clamp floors the distance at zero, and the screen says "Just now" over a fast that starts at the tap — the user's answer gone with nothing admitting it. These tests keep that true if anyone puts the moment back. Unit rather than Maestro because the defect needs the day to change with the sheet open, which no flow can stage.
- `MealPickerTests.testTheSameAnswerNamesTheSameMomentOnBothSidesOfMidnight` — the regression itself: the same answer read at 23:50 and ten minutes later at 00:00 must name the same wall-clock moment.
- `MealPickerTests.testMomentCountsWholeDaysBackRatherThanWrapping` — a distance longer than the day it is read in must count whole days back, not wrap inside one.
- `MealPickerTests.testMomentOnAnExactMidnightBoundary` — the case floor division gets wrong when written as truncating division.
- `MealPickerTests.testStateCannotHoldAValueOutsideTheDomain` — the clamp is on the way into the state, not only on the way out, so no reachable state holds a value outside the domain.
- `MealPickerTests.testFastStartFloorHoldsAtTheFarEndOfTheDomainToo` — both screens that turn a meal into a fast start go through `MealMath.fastStart`, so the floor cannot be present on one path and missing on the other (ARCHITECTURE.md, invariant 8).
- `MealPickerTests.testSnapIsOneMinuteAcrossTheWholeDomain` — the drum snaps to any minute, so a round clock time like 20:50 is reachable far from now instead of falling between two coarse ticks. The VoiceOver adjustment stays coarse at a uniform 15 minutes — a minute at a time would be thousands of swipes.
- `MealPickerTests.testPositionIsLinearInMinutes` — one minute is `pitch` points everywhere, which is what lets fling momentum carry reach without the step coarsening.
- `MealPickerTests.testPositionAndSnapAreInversesOnEveryStep` — otherwise the marker and the value disagree somewhere along the strip.
- `MealPickerTests.testScrubbingBackToNowReportsAsUntouched` — scrubbing back to zero is a return to "now", not an answer; reporting it as a ribbon answer would count back-dates that did not happen.
- `MealPickerTests.testTheSeededValueIsMarkedAsSeeded` — the window-close default is the app's own value and says so, so analytics can tell it apart from a chip the user tapped.
- `MealPickerTests.testInputMethodVocabularyIsFixed` — the raw values are a GA4 dimension's vocabulary; a rename compiles silently and splits the reports in two. `AnalyticsEventTests` does not catch this class of break — it checks only the value's type.
- `MealPickerTests.testDismissingThePickerPutsTheAnswerBack` — dismiss is cancel: a chip tapped and then dismissed must not survive, or the next tap on the primary starts a fast a day back — already in overtime, with a goal that can no longer be reached. The sheet applies as it is edited by design; the restore point is what undoes it.
- `MealPickerTests.testDismissingOverASeededValueKeepsTheSeed` — a dismiss is not a `cleared` in disguise: the value the app seeded was not the user's to lose by tapping the scrim.
- `MealPickerTests.testConfirmingKeepsTheAnswerTheSheetWasClosedOn` — the restore point exists for the dismiss path and must never be applied behind a confirm.
- `MealPickerTests.testADismissAfterAConfirmCannotUndoTheCommittedAnswer` — a confirm spends the way back. Nothing dispatches that pair today; the next way of closing the sheet someone adds would, and it would silently revert a started fast.
- `MealPickerTests.testASecondOpenTakesAFreshRestorePoint` — the second dismiss goes back to what the second open saw, not to the state before the first one.
- `MealPickerTests.testASpentRestorePointIsNotReused` — the restore point is spent when used, so a stray dismiss cannot resurrect an old answer.
- `MealPickerTests.testLastNightIsTheMostRecentEveningThatHasPassed` — one rule for all twenty-four hours: the most recent 9 PM that has passed.
- `MealPickerTests.testLastNightStepsBackWhenTonightHasOnlyJustBecomeEvening` — just after 9 PM the nearest past evening is minutes ago, and calling that "last night" would be nonsense, so it steps back a day; half an hour past the floor it is a normal, short "last night".

## ProReducerTests.swift

- `ProReducerTests` — the offer screen must never invite a purchase from someone who already owns Pro: with the entry point still set and the phase idle, the screen falls back to S1 with a live Buy button whose tap does nothing (`PurchaseProThunk` guards on `isPro`). The right can arrive three ways, so the guard is one rule over the state; the tests hold both halves — the offer closes once there is nothing left to sell, and stays up while an attempt still has something to say.
- `ProReducerTests.testApprovedAskToBuyConfirmsInsteadOfClosing` — Ask to Buy approved while the offer is up: the screen leaves S4 for the confirmation on its own, without a tap — money was taken, so it must not vanish either. The six-state value is about the frame, not about whether the frame is up; S6 is the one frame an owner can be shown.
- `ProReducerTests.testEntitlementGrantedWhileReadingTheOfferClosesIt` — the right arriving from another device or a family member's purchase while the offer is merely being read.
- `ProReducerTests.testStoreResolvingProClosesAnOpenOffer` — the store answering late: the offer opened at S5 because nothing had been checked yet, and the answer is that this install owns it.
- `ProReducerTests.testPurchaseCompletedConfirmsInsteadOfClosing` — a purchase says so before the screen goes: the frame is the confirmation and waits to be dismissed by hand. The close-in-front-of-an-owner rule leaves it alone because `.granted` is not `.idle`.
- `ProReducerTests.testClosingTheConfirmationLeavesNothingBehind` — dismissing the confirmation hands the offer back to the rule that refuses to stand open in front of an owner.
- `ProReducerTests.testRestoreCompletedKeepsTheOfferForItsConfirmation` — S6 is a confirmation the user has to see; the restore flow closes the offer afterwards.
- `ProReducerTests.testEntitlementArrivingMidPurchaseKeepsTheOfferOpen` — a transaction can report the entitlement before it reports itself finished; S2 stays up until it does.
- `ProReducerTests.testEntitlementArrivingOverAFailureKeepsTheOfferOpen` — the failure was about an attempt, and S3 is the frame that says so; it gets to finish.
- `ProReducerTests.testEmptyRestoreLeavesTheOfferStanding` — an empty restore settles the entitlement as `free`, which is not the right and closes nothing.
- `ProReducerTests.testHalfTheGoalIsTheThreshold` — T1' quality filter. The filter and the one-time flag are invisible when they work and break without anything going red; the offer is shown once in the life of an install, so a regression is not a reported bug but an offer that never appears, or appears on a fast abandoned after a minute. The boundary is checked from both sides because "less than 50%" versus "at least 50%" is the entire rule.
- `ProReducerTests.testReachingTheGoalQualifies` — reaching the goal needs no branch of its own; stated as a test so a later edit cannot "add the missing goal_reached case" and end up with two definitions of one predicate.
- `ProReducerTests.testTheThresholdFollowsTheGoalTheFastActuallyRanTo` — a custom goal is compared against itself, not a preset: on a 3-hour goal the threshold is 90 minutes.
- `ProReducerTests.testAnUnpinnedGoalDoesNotQualify` — state written before the goal was pinned resolves to the plan upstream; a zero arriving here is not a fast that qualified by dividing by nothing.
- `ProReducerTests.armed()` — free, verified, with a price, and a qualified fast just ended: every precondition of the automatic offer met, so each suppression test changes exactly one thing.
- `ProReducerTests.testAnInstallThatHasHadItsOfferNeverArmsAgain` — "exactly once, ever" held at the earliest point, so nothing later carries a plan that can never fire.
- `ProReducerTests.testTheOtherDoorsDoNotSpendTheFlag` — the other doors are the user's own action and say nothing about the automatic one; opening the offer from About does not use up the show the next finished fast has coming.
- `ProReducerTests.testDismissDoesNotBringTheOfferBack` — edge 11: after a dismiss it does not come back, this launch or any later one.
- `ProReducerTests.testCancellingAnArmedShowLeavesTheFlagWhole` — edge 20: the fast is taken back, so the show armed for it goes too — what stands between a mis-tapped End fast at 60% and a lifetime offer spent on it. In every suppression case the assertion that matters is `autoOfferShown` still false: the show moves to the next qualified fast and the install keeps its one offer.
- `ProReducerTests.testAReviewPromptSuppressesTheOfferWithoutSpendingIt` — the review prompt outranks the offer for the rest of the launch. `reviewPrompted` means the request was made — Apple may have shown nothing — which is exactly why suppressing on it has to be free.
- `ProReducerTests.testAnUnverifiedEntitlementSuppressesTheOffer` — edge 16: an unchecked entitlement gates like free, but the offer never opens on its own there — no inviting a second purchase of something this install may already own.
- `ProReducerTests.testAMissingProductSuppressesTheOffer` — the screen is a frame built around a price, and a store that did not answer cannot sell anything.
- `ProReducerTests.testAnOwnerHasNoPendingOffer` — edge 10: an owner is never shown any automatic trigger.
- `ProReducerTests.testAnAttemptInFlightSuppressesTheOffer` — an Ask to Buy still out with whoever approves it is an attempt in flight; the automatic offer does not interrupt it to sell the same thing again.

## ResumeFastTests.swift

- `ResumeFastTests` — undoing "End fast" from the result screen must restore the goal this fast was pinned to, not the plan as it stands now. Reusing `StartFastThunk` would compile and quietly re-pin it, so the fixture seeds a plan that disagrees with the pinned goal.
- `ResumeFastTests.completeState(stagedElapsed:pinnedGoalHours:planHours:records:)` — two hours staged, pinned to 18h, while the selected plan is 16h: the disagreement any re-pinning would show up as.
- `ResumeFastTests.testUndoDoesNotTouchStreakOrCompletionCounters` — reaching the goal counts a session and moves the streak; ending a fast does not, so undoing an ending leaves them alone. `hasCelebrated` is checked because clearing it would replay the goal moment on a resumed overtime fast, and the replay is what would double-count the other two.
- `ResumeFastTests.testStartTimestampCarriesTheStagedElapsed` — where a fast put in flight has its start is one definition, used by both the start path and the undo; asserted on `TimerState` rather than through either caller because neither caller owns it (ARCHITECTURE.md, invariant 8).
- `ResumeFastTests.testThunkDispatchesUndoAndNeverStart` — the distinction the whole thunk exists for; the count picks up where it left off rather than restarting from zero.
- `ResumeFastTests.testThunkDeletesNothingWhenTheEndingWroteNoRecord` — a fast shorter than `HistoryMiddleware.minimumDuration` still reaches the result screen but writes no record; deleting "the newest record" there would throw away the user's previous fast.
- `ResumeFastTests.testThunkIsInertWhileAFastIsRunning` — the action does not exist in `.active`, and a stray dispatch must not restart the clock.

## ReviewMiddlewareTests.swift

- `ReviewMiddlewareTests` — there are three review prompts in a lifetime. Nothing may be spent or logged until the native call reports it actually went out: Apple drops a request that lands on a scene that is not `foregroundActive`, which is exactly where the "next open" fallback lands on a cold start, and spending the attempt up front loses it while the funnel says "shown".
- `ReviewMiddlewareTests.RepoFake.callGoesOut` — what `requestReview` reports back; false means there was no active scene to ask on.
- `ReviewMiddlewareTests.RepoFake.holdsTheAnswer` — the real repository answers through `Task { @MainActor }`, never in the caller's frame. Holding the answer lets a test act in the window where the call is out and its result has not come back; `answerNow()` delivers it the way the main-actor hop eventually would.
- `ReviewMiddlewareTests.recordingDispatch(into:)` — the middleware's dispatch is where `review_prompted` is born; `AnalyticsMiddleware` only forwards it.
- `ReviewMiddlewareTests.testAttemptWithoutASceneDoesNotBlockTheNextOneInTheSameLaunch` — a cold start hits both: `onAppear` fires while the scene is still settling, the `scenePhase` change follows once it is active. The first must not consume the once-per-launch gate, or the second — the real one — is blocked.
- `ReviewMiddlewareTests.testSecondActionWhileACallIsInFlightDoesNotStartASecondCall` — between "asked" and "answered" every gate still reads as open, and both `appBecameActive` and a closed milestone card can land inside it. One call at a time, or one attempt buys two requests.

## SourceAnalyticsTests.swift

- `SourceAnalyticsTests` — the reading funnel: which paper was read, whether anyone went on to the paper itself, and whether the reader was closed at the end or at the top. The identifier is the catalog index and travels as text — the papers are read as a distribution, sorted by the dimension, and a number logged as a number leaves the dimension `(not set)`.
- `SourceAnalyticsTests.LinksStub` — the thunk takes its repository from the container, which is registered at app launch and not in a test bundle; handed one explicitly, it can be built here without the launch path.
- `SourceAnalyticsTests.testEachArticleReportsItself` — with four titles in the list, an event that could not tell them apart would answer none of the questions it exists for.
- `SourceAnalyticsTests.testReachedEndTravelsAsTextNotAsABool` — a `Bool` at the call site bridges to `NSNumber`; logged as it stands, the breakdown comes back empty.
- `SourceAnalyticsTests.testNoEventCarriesATitleOrAURL` — the titles are localized (ten vocabularies in one dimension), and the URL is the one value the event is required not to carry.
- `SourceAnalyticsTests.testOpeningAnExternalLinkOnItsOwnReportsNothing` — `OpenExternalLinkThunk` also opens the privacy policy and system Settings, so `source_original_opened` hangs off a lifecycle action dispatched at the one call site, not off the thunk. A thunk passing through the analytics middleware must leave no event behind, or the event stops counting papers and only papers.

## StreakFreezeTests.swift

- `StreakFreezeTests` — the protected day: one missed day per calendar month kept from breaking a run, Pro only. It is sold by name on the offer screen and in store texts, so both halves it is sold as are held here: the run survives one missed day, and buying Pro during the day a break became visible undoes that break (edge 8). Two surfaces, one rule: `StreakStatus.freezeCovers` decides, the reducer debits the month, and `displayed(at:)` is what the user sees — a rule held in the reducer alone would still show the run dropping to zero for a day and coming back.
- `StreakFreezeTests.testOneMissedDayIsCoveredForPro` — charged to the month of the missed day (2 August), not of the goal.
- `StreakFreezeTests.testOneMissedDayStillResetsWithoutPro` — no month is charged for a benefit that was never held.
- `StreakFreezeTests.testTwoMissedDaysResetEvenForPro` — one protected day protects one day; the allowance stays untouched for the month it may still be needed in.
- `StreakFreezeTests.testNewCalendarMonthRestoresTheAllowance` — a calendar month, not a rolling thirty days.
- `StreakFreezeTests.testMissedDayOnTheLastOfTheMonthIsChargedToThatMonth` — the month boundary sits under the missed day, not under the goal that banks it: 31 August is August's, so September's allowance is still whole. `hasCelebrated` is reset by hand because the next fast clears it, and only that lets a second goal moment through.
- `StreakFreezeTests.testFirstDayOfNewMonthIsCoveredAfterAugustWasSpent` — the mirror of the case above, and the one a rolling window would get wrong.
- `StreakFreezeTests.testConsecutiveDayDoesNotSpendTheFreeze` — the allowance is for gaps; a Pro user who never misses still has it when they finally do.
- `StreakFreezeTests.testBrokenRunCarriesItsLastGoalDate` — the projection carries the run's final goal day so history can name when that run ended rather than show an unexplained number.
- `StreakFreezeTests.breakInstant(afterLastGoal:)` — the break becomes visible at the midnight starting the day after the missed one; through the missed day itself the run still counts as extended yesterday.
- `StreakFreezeTests.testPurchaseAtHour23RestoresTheBrokenRun` — edge 8: bought within 24 hours of the break, the run is whole again with no action from the user and no sheet in between.
- `StreakFreezeTests.testPurchaseAtHour25DoesNotRestoreTheBrokenRun` — past the window a second day has been missed, and no purchase reaches back that far.
- `StreakFreezeTests.testAbsentStoredMonthCountsAsUnspent` — an install updating from before the feature has no stored month, which reads as unspent: someone who just paid gets the benefit, not a month of waiting.

## SunnahAnalyticsTests.swift

- `SunnahAnalyticsTests` — `sunnah_opened` has to keep its two doors apart (the second door exists on the suspicion that the first is never found). `sunnah_enabled` has to fire once per switching-on, while every control on the screen writes through `SunnahAction.settingsChanged` and `deliveryUpdated` is also raised by a cold start, a foreground, a day change and a time-zone change. So the event hangs off an edge — nothing scheduled before the write, something after — which exists only in the middleware's snapshot of the previous state. Half the tests are the traps (a time nudged, a second schedule added, one of two switched off): counted as "a write landed on an enabled schedule", each is a false arming, and GA4 backfills nothing.
- `SunnahAnalyticsTests.disarmed` — the state before anyone touches the screen, and the one the reducer resolves a disabled settings blob back to.
- `SunnahAnalyticsTests.arming(weekly:whiteDays:)` — what the reducer leaves on a write that arms: settings on, delivery `.checking` while the middleware goes and asks.
- `SunnahAnalyticsTests.arm(weekly:whiteDays:answer:on:)` — the leading `refresh` is not decoration: the middleware's "how things stood before" is taken from the previous action it saw, so without one the test would assert against `nil` rather than a disarmed screen.
- `SunnahAnalyticsTests.testArmingAScheduleReportsTheModeAndThePermission` — the permission travels as text, not as a `Bool` that would reach GA4 as a number.
- `SunnahAnalyticsTests.testArmingWithNotificationsRefusedReportsThePermissionAsMissing` — the cohort `push_allowed` exists for: the schedule is on and no reminder can be delivered. Not an error on the event, a fact about the permission ask.
- `SunnahAnalyticsTests.testBothSwitchesReportOneEventInTheCombinedMode` — both switches flipped before the first answer is one switching-on in a third mode, not two events.
- `SunnahAnalyticsTests.testARefreshOverASettledScheduleIsSilent` — a refresh produces the same `deliveryUpdated` with nobody touching anything; counted there, the event would report an arming on every launch of every user who ever turned the feature on.
- `SunnahAnalyticsTests.testASecondAnswerToTheSameArmingDoesNotReportTwice` — the permission dialog resolving and the middleware scheduling again is the same arming.
- `SunnahAnalyticsTests.testMovingTheReminderTimeOnAnArmedScheduleReportsNothingNew` — the reminder-time control is a wheel that writes once per detent through the same action as a switch.
- `SunnahAnalyticsTests.testAddingTheSecondScheduleToARunningOneReportsNothingNew` — the reminders were already on; read the other way the event would count a person once per schedule they ever added.
- `SunnahAnalyticsTests.testASecondSwitchFlippedBeforeTheAnswerStillReportsOneArming` — the note an arming leaves is spent by the delivery answer, which can take the whole length of the permission dialog. Clearing it on a second write inside that window would swallow the switching-on for exactly the people who turned both schedules on at once.
- `SunnahAnalyticsTests.testSwitchingEverythingOffBeforeTheAnswerCancelsTheArming` — no schedule is left for the answer to describe.
- `SunnahAnalyticsTests.testSwitchingOffOneOfTwoSchedulesIsNotAnArming` — the sharpest trap: switching one of two off leaves the settings enabled and writes the same action, so a level check would count disarming half the feature as turning it on.
- `SunnahAnalyticsTests.testTurningTheRemindersOffReportsNothing` — it does not even reach the delivery branch: the reducer resolves a disabled schedule straight to `.off`.
- `SunnahAnalyticsTests.testReArmingTheSameModeAfterSwitchingOffReportsAgain` — the edge is the fact, not the value.
- `SunnahAnalyticsTests.testOnlyAnArmedScheduleReachesTheCheckingState` — the reducer's half, asserted where it lives: a disabled blob never reaches `.checking`, so the delivery branch is only entered over a schedule that exists.
- `SunnahAnalyticsTests.testModeVocabularyIsFixed` — guarded like `MealInputMethod`: the raw values are a GA4 dimension, and a rename compiles silently while cutting the report in two.

## SunnahMiddlewareTests.swift

- `SunnahMiddlewareTests.Repository.replace(_:)` — sleeps after starting a non-empty write to model an in-flight write: cancellation alone does not undo it, so disabling has to wait for the older write and then clear it.
- `SunnahMiddlewareTests.testDeniedPermissionClearsRequestsAndReportsDenied` — a refusal delivers no dates: the upcoming list is what was scheduled, and with the permission denied nothing was. Otherwise the screen prints fasting dates under a green switch while no reminder can fire. The expectation is fulfilled inside the recorder's `Task`, so the assertion cannot read the recorder before the value lands in it.
- `SunnahMiddlewareTests.testGrantedPermissionStillDeliversUpcomingDates` — the control for the case above: the check is about the refusal, not about the dates having gone away.

## SunnahScheduleTests.swift

- `SunnahScheduleTests.testDSTUsesLocalHourRatherThanFixedTwentyFourHourOffsets` — New York falls back on 1 November 2026, so Sunday 20:00 local is Monday 01:00 UTC; adding fixed 24-hour offsets would land an hour off.
