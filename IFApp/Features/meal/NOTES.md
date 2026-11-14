# Meal - notes for agents

Why the last-meal picker's code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## MealState.swift

- `MealState` — the picker's single source of truth, and it stores the **distance** the user chose ("forty minutes ago"), not the wall-clock moment it resolves to. The question on screen is "how long ago did you eat"; the ribbon and the chips are distances. Turning a distance into a moment needs "now", and the only correct "now" is the instant the fast actually starts — `ConfirmLastMealThunk`, not the instant the finger left the ribbon. Storing the moment means resolving it early against a clock read somewhere in the view, which is how a picker jumps into the future across midnight: the day offset computed against one "now" and read back against another.
- `MealState` — keeping the distance also keeps `MealAction` free of time, so the reducer needs no injected clock (invariant 1) and the view has no reason to read one into a payload (invariant 6). `(ateDay, ateMin)` is only how the value is *displayed*, derived on the spot by `MealMath.moment`.
- `MealState.minutesAgo` — 0 means "now / starting fresh": the live moment, which stays live however long the sheet is open instead of freezing on the minute it opened.
- `MealState.chipIdx` — a separate source of truth from the value, -1 = none: landing on 60 minutes by dragging the ribbon is not the same act as tapping "1h", and only the tap lights a pill.
- `MealState.inputMethod` — carried into `last_meal_logged` so the scale can be retuned against how people actually answer.
- `MealState.restorePoint` — the three fields as they stood when the picker opened. The sheet has no draft of its own: the ribbon, the readout and the pill behind the scrim all read this one value, which is what keeps the pill truthful while the sheet is up. The cost is that an edit applies the moment it is made, so "dismiss = cancel" needs somewhere to put the previous answer back from. Optional on purpose: a dismiss with nothing to restore is a no-op rather than a revert to whatever was last seen, so `MealAction.pickerDismissed` cannot resurrect a stale answer if it ever arrives without an open sheet before it.
- `MealState.Snapshot` — one value, so the three fields cannot be put back one at a time and drift apart in between.
- `MealState.set(minutesAgo:chip:via:)` — the one place the value changes; all four ways of answering go through it, so the clamp and the chip/input bookkeeping cannot drift apart between them. A value clamped to zero is "now" however it was reached, and "now" is not a back-date, so a ribbon answer of zero reports as `untouched`.
- `MealState.markPickerOpened()` — overwrites unconditionally: the answer to put back is the one on screen this time, never one from a sheet two openings ago.
- `MealState.revertToRestorePoint()` — spends the restore point. Confirming does not come through here; it keeps what was chosen.
- `MealState.forgetRestorePoint()` — the answer the point described no longer exists to go back to.
- `MealInputMethod` — a GA4 dimension: raw values are fixed ASCII, never localised. Three are the ways a person answers (chip, ribbon, exact); `untouched` is a sheet confirmed as it stood and `seeded` a value the app put there from the closed eating window. Folding either into the three would report taps that never happened — the error that made `backdated` unreadable.
- `MealChip` — all but `lastNight` are fixed offsets from now; `lastNight` resolves against the clock in `PickMealChipThunk`.
- `MealChip.lastNightMinuteOfDay` — the evening "Last night" means: the most recent 9 PM that has passed.
- `MealChip.lastNightFloor` — below this the reading is absurd (tonight, minutes ago), so the chip steps back one more evening.

## MealAction.swift

- `MealAction` — every case carries a distance in minutes and nothing else; no case needs a clock to apply, so the reducer stays pure without one being injected. The moment is resolved once, at confirm, against the clock of that instant.
- `MealAction.initialized(minutesAgo:)` — a distance the app worked out itself (the window-closed default), applied only while unset. Lights no chip: the value came from the app, not a tap.
- `MealAction.scrubbed(minutesAgo:)` — drops any chip selection; the ribbon is the source of truth from then on.
- `MealAction.chipPicked(idx:minutesAgo:)` — sets the value *and* keeps the chip lit.
- `MealAction.exactTimePicked(minutesAgo:)` — deliberately off the ribbon's snap grid.
- `MealAction.pickerOpened` — carries no value: it only marks where to come back to if the sheet is dismissed instead of confirmed.
- `MealAction.pickerDismissed` — the scrim, or anything else that closes the sheet without confirming; puts the answer back as it stood on open. Separate from `cleared` because they mean opposite things: `cleared` says "there is no answer any more", this says "keep the answer you had" — dismissing a sheet opened over a seeded window-close time must not throw the seed away.
- `MealAction.pickerConfirmed` — changes no value (the answer already stands); it only spends the way back. Without it the snapshot outlives the confirm, and a `pickerDismissed` arriving afterwards — from whatever way of closing the sheet gets added next — would quietly undo a committed answer.

## MealReducer.swift

- `mealReducer(state:action:)` — `.initialized` applies only while `isFresh`: a seed must never overwrite an answer.

## MealMath.swift

- `MealMath` — pure; "now" is injected so these are testable.
- `MealMath.clamped(_:)` — the domain clamp, and the only one. A meal in the future would back-date the fast *forward* (the timer counting from a start that has not happened while the readout says "Just now"), and a meal further back than the ribbon reaches is not one either. Every way a distance enters the model — ribbon, chip, exact time, the window-close seed — goes through `MealState.set`, which goes through here.
- `MealMath.fastStart(minutesAgo:now:)` — one definition for `ConfirmLastMealThunk` and `ContinueFastingThunk`, which answer the same question from different screens; two copies of the arithmetic drift (only one carrying the floor). The floor is `clamped`: a non-negative distance cannot produce a start in the future, so no caller has anything to remember.
- `MealMath.moment(minutesAgo:nowMinuteOfDay:)` — clamped to the same domain, so nothing upstream can hand the labels a moment the model cannot hold. Floor division: `total` goes negative once the meal is before today's midnight, and truncating division rounds that the wrong way.
- `MealMath.timeLabel(ateMin:)` — `Locale.latinDigits` (Latin digits and Gregorian calendar), so this clock reads the same as the hand-built numerals beside it.
- `MealMath.fromLabel(minutesAgo:nowMinuteOfDay:)` — the clock time is isolated in all three branches, the bare one included: every caller composes the value further ("… · 2h 40m in" in the picker preview, `fastCountsFrom` in the subline), and by then the clock is a token mid-line. Isolating where the clock enters the string, not where it ends up, keeps that true for the next caller.
- `MealMath.agoLabel(minutesAgo:)` — one whole localised template per shape, never a duration plus a separate "ago": the word sits in front in de/es/fr/ar and behind in uk/pl/ja/ko. The shape stays fixed inside a band even when a component is zero ("23h 00m ago", "1d 0h ago"): the headline is centred, and dropping the zero shortens it by four or five characters, so it would jump sideways as the value moves. A shape changes only at a band edge, where the unit itself changes.
- `MealMath.absoluteLabel(ateDay:ateMin:)` — the line under the headline is where the calendar lives: there is no date control, the day follows from the chosen moment.
- `MealMath.shortDayLabel(daysAgo:)` — "Yesterday" for the first midnight rule back, weekday abbreviations for the rest.
- `MealMath.dayFormatters` — cached because `shortDayLabel` is called from inside the ribbon's `Canvas` draw, once per midnight rule on screen, every frame of a drag; building `DateFormatter`s per frame stutters the one gesture this screen exists for. Keyed by locale as well as template, so a language change does not keep serving the previous language's day names. Main-thread only: both callers draw.

## MealScale.swift

- `MealScale` — geometry of the last-meal ribbon: how "minutes ago" maps to points on a strip longer than the screen. A native-style drum: one minute per detent across the whole domain, so a slow drag lands any exact minute and a hard flick carries through hours on momentum, as a system wheel does. A scale that coarsens far from now leaves round times (20:50) between two ticks, unlandable. Retuning the feel is `pitch` here plus the momentum in `MealScaleRibbon`.
- `MealScale.pitch` — points per minute, constant along the strip. Small, because reach is carried by fling momentum, not by fitting the domain on one screen.
- `MealScale.maxMinutes` — the hard floor of the domain: the app does not back-date further than 7 days.
- `MealScale.stepMinutes` — with a one-minute step the index *is* the minute; kept as an array because the ribbon walks it by visible index when it draws.
- `MealScale.step(at:)` — the VoiceOver adjustment step, deliberately coarser than the snap: a minute per swipe would be ten thousand swipes across the domain.
- `MealScale.labelKind(at:)` — a label every hour and every whole day (whole days read "1d", not "24h"); only about an hour of strip is on screen at once, so hourly labels are legible, not crowded.

## ConfirmLastMealThunk.swift

- `ConfirmLastMealThunk.execute(state:dispatch:)` — the only place the chosen distance becomes a moment, against the clock of the instant the fast actually starts.
- `ConfirmLastMealThunk.execute(state:dispatch:)` — `backdated` is read off the distance, not off "the picker has a value": the sheet does not seed itself on open, so the flag tells a real back-date from someone opening the sheet and confirming straight away.
- `ConfirmLastMealThunk.execute(state:dispatch:)` — confirming from the window-closed screen chains the next fast (`fastChained`).
- `ConfirmLastMealThunk.execute(state:dispatch:)` — dispatches `pickerConfirmed` to spend the way back: this answer is committed.

## PickMealChipThunk.swift

- `PickMealChipThunk` — three chips are fixed offsets; "Last night" is the one that needs the clock.
- `PickMealChipThunk.lastNightMinutesAgo(nowMinuteOfDay:)` — the most recent 9 PM that has passed: one rule for all 24 hours, no night-time branch. At 3 AM that is yesterday evening, which is what both the person still awake and the one who just woke mean. The one guard: right after 9 PM the nearest past evening is *tonight*, minutes ago, so it steps back a day (`MealChip.lastNightFloor`).

## SetExactMealTimeThunk.swift

- `SetExactMealTimeThunk` — the precise path, a moment from the system date picker. Not rounded to the ribbon's grid: someone who went looking for 7:52 PM wants 7:52 PM, and snapping it would remove the only reason to open the picker.
- `SetExactMealTimeThunk.execute(state:dispatch:)` — the picker's own range already stops at "now"; the clamp is what makes a future start unrepresentable rather than merely unreachable.

## SeedLastMealFromWindowCloseThunk.swift

- `SeedLastMealFromWindowCloseThunk` — seeds the control to the moment the eating window closed, so "Continue fasting" back-dates from there by default. The close moment and "now" are resolved here, not in the view, so the offset is measured when the seed is dispatched, not whenever the screen redrew.
- `SeedLastMealFromWindowCloseThunk.execute(state:dispatch:)` — a distance, not a calendar day offset: a window that closed further back than the ribbon reaches clamps to the 7-day limit instead of landing on a plausible-looking wrong time of day.

## MealFeedbackThunk.swift

- `MealFeedbackThunk` — the ribbon decides *whether* to ask (it owns the velocity and the throttle); touching the taptic engine is a side effect, so it happens here, not in the view.
- `MealScrubFeedback.begin` — nothing to feel yet; only warms the engine.
- `Taptic` — the generators outlive a single tick on purpose: a fresh generator has to wake the taptic engine, late enough that the first click of a drag is late or lost, and the scrub feels like silence followed by a rattle. Kept alive and re-armed after every fire, the ribbon clicks like a system picker.
- `MealFeedbackThunk.execute(state:dispatch:)` — `.step` re-arms straight away: the next step is at most 45 ms out (the ribbon's throttle in `MealScaleRibbon`).
- `MealFeedbackThunk.execute(state:dispatch:)` — `.edge` — the tick label at the end reads "7d"; a screen reader gets the sentence, since it has no end-stop to feel.
