# History - notes for agents

Why the history feature's code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## HistoryAction.swift

- `HistoryAction.recorded` — dispatched by `HistoryMiddleware`, which owns the write; the reducer only mirrors the saved record into state.
- `HistoryAction.exportFailed` — releases the control for a retry; the export lifecycle cases are transient.
- `HistoryAction.exportFinished` — `shared` is false when the user backed out of the share sheet. Only `true` is an export that happened: cancelling is not an event.

## HistoryState.swift

- `HistoryState` — finished fasts, newest first. The whole array lives in state so the screen's aggregates recompute themselves after a delete without any bookkeeping.
- `HistoryState.latestRecord` — the fast that ended last: the one the eating window card reports and the review prompt qualifies on. By end time rather than array position, so it does not depend on the order the records were loaded in.
- `HistoryState.exportFile` — the CSV waiting for the share sheet. The sheet is up exactly while this has a value, so the screen cannot be sharing a file that no longer exists. Not persisted: the file lives in the temporary directory, and an export is finished the moment the sheet closes.
- `HistoryState.isExporting` — transient; never persisted with the user's history.
- `HistoryState.isExportBusy` — no new export while one is being written or the last one is still up in the share sheet. The button disables on it and `ExportHistoryThunk` refuses on it: one predicate, defined here once.

## FastRecord.swift

- `FastRecord` — only the raw facts are stored; duration, goal reached, the phase it ended in and midnight crossings are derived. Anything cached would have to be kept in sync on deletion; derived values cannot drift.
- `FastRecord.startTimestamp` — epoch seconds the fast began, after any back-dating.
- `FastRecord.goalHours` — the goal at the time the fast ended.
- `FastRecord.planLabel` — stored as text ("16:8") rather than derived or indexed, so a later change to plans cannot retroactively relabel old records.
- `FastRecord.goalFraction` — clamped to 1 for the ring arc.
- `FastRecord.reachedPhase` — the phase the fast actually ended in; the row's ring colour.
- `FastRecord.isExtended` — past a full day: the `Extended` chip and a second inner arc (`extendedFraction`, hours past 24h as a fraction of a second day).
- `FastRecord.goalDayKey` — the local day this fast credits to the streak, by the same rule the live streak uses (`Clock.goalDayKey`); nil when the goal was never reached.
- `FastRecord.overlaps(start:end:)` — half-open on both sides, which settles the three cases deciding whether a back-dated ending may be written:
  - end to end — a fast beginning exactly when a saved one ended is not an overlap; it is the ordinary shape of a day, and refusing it would refuse the common case;
  - nested — a span entirely inside a saved one is an overlap: two records for one night would have `TOTAL` count the shared hours twice;
  - identical bounds — an overlap: two records naming the same span are the same fast written twice, whatever the arithmetic of touching says.
- `FastRecord.firstOverlap(in:start:end:)` — newest first, because that is the record the person most likely recognises, and the refusal names exactly one.

## HistoryExport.swift

- `HistoryExport` — a pure derivation over the records: no clock, no file system, no locale; the same records give the same bytes. The file is machine-readable end to end on purpose: the header is a column key, not a caption, so it is one fixed ASCII line in all ten locales (ten translated headers would be ten formats of one file), and every value follows it — ISO-8601 with the local offset, whole integers, `true`/`false`, phase codes from a fixed list. Nothing here is ever localised. Two consequences not to "fix" later:
  - every byte is ASCII, so the BOM question and the whole class of 文字化け bugs do not exist — true only while no column is localised;
  - no column carries a decimal separator, so dot-versus-comma cannot break an import on a de/fr/es/pl/uk machine — a property, not an agreement.
- `HistoryExport` — no `plan` column: `planLabel` follows entirely from `goal_hours`, so it would add no information while forcing a choice between the machine spelling of a custom plan and the displayed one.
- `HistoryExport.header` — also the format's version marker: a future parser tells formats apart by this line, which is why no comment line is added to the file.
- `HistoryExport.newline` — RFC 4180's `\r\n`. Excel on Windows is the one target that still cares, and it is exactly the target the ASCII rule was written for.
- `HistoryExport.csv(records:)` — rows run oldest first, not in the screen's order. The reader is a spreadsheet or a script: descending rows give a mirrored time axis on any chart drawn from a raw import. The cost is accepted: opening the file in Numbers just to look shows the oldest fast first.
- `HistoryExport.csv(records:)` — no field is quoted or escaped, and that holds by construction: every column is an ISO timestamp, an integer, `true`/`false` or a code from `Phase.exportValue`, none of which can contain a comma, a quote or a newline. The day a column stops being machine-generated, this needs quoting.
- `HistoryExport.timestamp(_:)` — "2026-08-04T07:12:00+03:00": the local offset, never `Z`. A fast that began at seven in the morning means seven in the morning; the offset keeps both readings and still sorts lexicographically. `ISO8601DateFormatter` takes no locale — it is fixed on the proleptic Gregorian calendar and Western digits — which keeps ar_SA from writing Hijri dates in Eastern Arabic numerals into a data file.
- `HistoryExport.fileName(dayKey:)` — ASCII in every locale, like the contents: Windows and mail clients mangle non-ASCII names, an Arabic name carries bidi ordering into paths, headers and subject lines, and a support conversation has to be able to say the name out loud. Built from a literal, not from `strings.History.title`: that key is the screen title, and sourcing the name from it would let an edit to the heading silently rename the file. `dayKey` is the ISO date, so the files sort by name.

## HistoryStats.swift

- `HistoryStats` — every number on the history screen is a pure function of the full record array, computed at render. No incremental counters: a running `total += duration` makes deletion expensive and lets the displayed totals drift from the data. At a few thousand records this is microseconds.
- `HistoryStats` — a paywall may hide *rows* beyond a window, but must never narrow the input here: totals that shrink the day a paywall lands read as a bug, or as something taken away.
- `HistoryStats.total` — seconds, not whole hours. Truncated to hours the sum can print *below* the longest fast it contains — one 16h 01m fast gives "TOTAL 16h · LONGEST 16h 01m" on the same card, arithmetic that cannot be true. The month headers still drop minutes (a different scope with nothing beside them to contradict). The direction is forced: the longest fast cannot give up its minutes, because they are the personal best.
- `HistoryStats.compute(records:now:)` — two day sets on purpose. Rows are dated by the day the fast started, so the seven-day strip uses that visible date (`historyGoalDays`): an overnight fast starting Tuesday and crossing its goal Wednesday must light Tuesday, as its row says. The best streak keeps `goalDayKey`, the day the goal was actually crossed.
- `HistoryStats.showsFirstNote(fastsCount:streakCount:)` — the beginner note is gated on both stores the card reads: the streak counter lives in the timer's persisted defaults (since 1.4.4), the records in a file (since 1.4.5), and nothing backfilled one from the other. Counting only records would welcome everyone updated from 1.4.4 as a first-timer under a four-day streak. The note shows while the history is short *and* the counter claims nothing the records cannot account for; the ordinary first fast (one record, streak of one) still gets it. Takes the raw counter, not `displayed(at:)`: a streak that lapsed yesterday displays as 0 and is still not a beginner's.
- `HistoryStats.monthGroups(records:)` — grouped by the month a fast *started*, because the row shows its start date. The month is Gregorian (`Clock.gregorian`), like every day the app counts and like `HistoryFormat.monthTitle`. `Calendar.current` would put an Arabic device on the Hijri calendar: the bucket's first day, rendered through the Gregorian formatter, lands in the previous Gregorian month — September records under "أغسطس 2026".
- `HistoryStats.lastSeven(goalDays:now:)` — seven flags, oldest first.

## HistoryMonthGroup.swift

- `HistoryMonthGroup.id` — "2026-07", stable across locales, used only as identity.

## HistoryDay.swift

- `HistoryDay` — carries the date with the flag so the UI can label each dot, instead of seven anonymous circles whose direction and meaning have to be guessed.

## HistoryFormat.swift

- `HistoryFormat` — formats come from the locale (de gets 24h and "Fr 24. Juli"), digits are forced Latin like everywhere else in the app, and time tokens are wrapped in `BidiText.isolate` so "8:40 PM" does not come apart inside an Arabic sentence.
- `HistoryFormat.latinLocale` — Western digits and the Gregorian calendar pinned. The calendar matters: ar_SA would otherwise render Hijri dates here while the streak, the seven-day dots and every day key are counted on Gregorian days, so the list and the numbers above it would describe different days. Shared with the string catalog's integer substitutions (`Locale.latinDigits`) so both paths render the same digits on one screen.
- `HistoryFormat.monthTitle(_:)` — uppercased at the call site's discretion.
- `HistoryFormat.weekdayNarrow(_:)` — only the compact label under a seven-day dot; the full dates still drive the dots.
- `HistoryFormat.summaryDuration(_:)` — summary cards describe scale, not timestamps: rounded whole hours until two days, then rounded whole days. Exact hours and minutes stay in the rows.
- `HistoryFormat.totalHours(_:)` — an aggregate of many fasts, where minutes are noise.
- `HistoryFormat.rowSubline(_:isRTL:)` — a fast past 24h shows the date range instead of both clock times, because the long form does not survive ×1.5 translation growth on one line.

## ExportHistoryThunk.swift

- `ExportHistoryThunk` — a thunk for both reasons at once: the clock is read for the file name's date, and the write is a side effect, so neither may happen in the view or the reducer.
- `ExportHistoryThunk.execute(state:dispatch:)` — the empty-history guard is the second one, not the first: the export row does not exist on an empty history.

## HistoryEmptyState.swift

- `HistoryEmptyState` — ghost rings rather than an icon: the ring is the app's one shape, and an empty one says "waiting to be filled" without a single zero on screen. The copy promises what will be kept; it never scolds.
- `HistoryEmptyState.body` — button — hugs its label rather than spanning the screen like the footer's primary button: an invitation, not the screen's main action.

## HistoryEmptyAction.swift

- `HistoryEmptyAction` — there is always exactly one button, and the state never appears without it: an empty screen whose only interactive thing is a bare chevron is a dead end, and hiding a dead CTA would deepen it. The copy above does not vary — "no fast has finished yet" is the reason either way; only the way out changes.
- `HistoryEmptyAction.backToFast` — a fast is already running and `StartFastThunk` refuses a second, so the honest action is the way back to it. The label names where it leads rather than "Back": the chevron already says that.
- `HistoryEmptyAction.identifier` — `history.startFast` and `history.empty.backToFast` are addressed by the Maestro flows (H7, H13); keep them.

## DeleteFastSheet.swift

- `DeleteFastSheet` — a bottom sheet for the same reason as `ResetConfirmSheet`: on iOS 26 the system `.confirmationDialog` renders as a popover that hides the `.cancel` button, leaving only the destructive action on screen.
- `DeleteFastSheet.sheet(bottomInset:)` — the confirm button is red: destructive, so it does not borrow the app's green primary button.

## PhaseRingMini.swift

- `PhaseRingMini` — the list's 40pt echo of the main ring: the arc fills to the fraction of the goal reached, in the colour of the phase it ended in, so the list shows the depth of each fast without a chart. A fast past 24h draws a second inner arc for the hours beyond the day.
- `PhaseRingMini.fraction` — a round cap on a near-zero arc renders as a bare dot; the 3° minimum keeps a very short fast reading as an arc.
- `PhaseRingMini.body` — never mirrored in RTL: progress runs clockwise from twelve in every locale. `.environment(\.layoutDirection, .leftToRight)` is what enforces it: RTL negates `rotationEffect`, so without the pin the −90° start becomes +90° and every arc in the Arabic list begins at six o'clock.

## ShareSheet.swift

- `ShareSheet` — Apple's surface, presented and not styled; the handoff leaves it out of the mockup on purpose. A bridge to `UIActivityViewController` rather than `ShareLink` because the export event fires only on a share that happened, and `ShareLink` has no completion.
- `ShareSheet.onFinish` — `true` only when an activity actually ran; backing out reports `false`.

## HistorySummaryCard.swift

- `HistorySummaryCard` — what the history adds up to; its numbers always come from the whole history, never from the slice of rows on screen. It reveals itself in stages: not shown at zero records (a wall of zeroes reads as a reproach to a beginner), dots from three records, the best-streak line from seven — nothing on screen is an empty promise.
- `HistorySummaryCard.display` — projected in `StreakStatus.display(at:)`, the same value the header pill draws, so the number and the sentence under it cannot come from two readings of one counter.
- `HistorySummaryCard.showsFirstNote` — passed in, not derived here: the rule needs the streak counter as well as the record count, and lives once in `HistoryStats.showsFirstNote`.
- `HistorySummaryCard.streak` — the persisted counter (live run or the one that ended), never `bestStreak`, which is recounted from the rows and can be smaller than the run just lost.
- `HistorySummaryCard.counterSpacing` — CJK writes a counter solid against its counter word ("6일 연속"), Latin and Cyrillic need the space ("6 днів поспіль"). Number and unit are two `Text`s (the number is display type), so the space is the stack's and has to follow the locale.
- `HistorySummaryCard.showsDots` — under three records the dots would be mostly empty.
- `HistorySummaryCard.showsBest` — needs a week of history, and must not contradict the number above it: `bestStreak` is counted from the records, the current streak from the carried-over counter, so after an update from 1.4.4 "Best 3" could sit under "20 days in a row".
- `HistorySummaryCard.body` — overline — it is the overline that relabels the number as past; the sentence below carries the fact that the run ended, and putting it up here would cost the slot its slack in Ukrainian.
- `HistorySummaryCard.body` — counter — `Text(verbatim: String(streak))`, not `Text("\(streak)")`: the `LocalizedStringKey` path lets the locale format the integer, giving Arabic-Indic "٦" beside the Western "118" of the totals.
- `HistorySummaryCard.body` — counter colour — drained of accent once the run is over, as the pill drains it: still the person's number, no longer going anywhere.
- `HistorySummaryCard.body` — text slot — the three branches are exclusive and the ended run comes first: it is the only one that says something the number does not already say.
- `HistorySummaryCard.body` — first note — no accessibility identifier of its own: SwiftUI folds the card's leaves under the container's `history.summary`, so one here never resolves and an assert on it proves nothing. The flow matches `history.summary` plus the note's text.
- `HistorySummaryCard.body` — totals — aggregates show scale, not stopwatch precision: the card rounds to hours then days, minutes stay in the rows.
- `HistorySummaryCard.stat(_:_:_:)` — labels shrink inside their own third rather than wrapping: German runs long ("Am längsten"), and a wrapped label would shift the row's baseline.

## StreakDots.swift

- `StreakDots` — a missed day is an unfilled ring, not a cross: the gap is a fact, not a verdict.

## HistoryRow.swift

- `HistoryRow` — a fast that fell short is coloured, not flagged: an open arc, the goal quietly beside the duration, and the phase it honestly reached. Nothing says "failed" — a user who feels judged stops recording the bad days.
- `HistoryRow.body` — duration — "41 Std 12 Min" beside the Extended chip is the widest this line gets; it shrinks rather than losing its minutes.
- `HistoryRow.body` — subline — one line, always: Arabic and German run past the width on the longest rows (a 40h fast spelling two dates), so the line gives up a little size before characters.
- `HistoryRow.tag` — either the goal a short fast fell short of, or the Extended chip past 24h.
- `HistoryRow.accessibilityLabel` — one spoken sentence per row; the ring is decorative and hidden. The plan is spelled out ("fasting plan, 17 hours") rather than read off the pill: `planLabel` is a ratio ("17:7"), and a colon between numerals is announced as a time of day — a row already speaking the real start and end times would gain a third, invented one.

## HistoryRowDetail.swift

- `HistoryRowDetail` — read-only by design: the one destructive path is an explicit swipe with a confirmation, so an accordion opened by a tap can never delete anything and the screen owes no undo.
- `HistoryRowDetail.detailRow(_:_:)` — the only place both ends of a fast are spelled out with date and time; the row leads with the start date, which is what the user recognises it by.
