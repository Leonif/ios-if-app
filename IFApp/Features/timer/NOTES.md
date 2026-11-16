# Timer - notes for agents

Why the timer feature's code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## TimerState.swift

- `TimerState` — elapsed time is not stored: it is derived from `fastStartTimestamp` and a moment the caller passes in (`elapsed(at:)`). Every derivation here that depends on time takes `now` as an argument and never reads the clock itself, so the reducer, the bootstrap and the tests can ask it about any moment (invariants 1 and 6).
- `TimerState.fastStartTimestamp` — epoch seconds; 0 = no running fast.
- `TimerState.goalHours` — pinned at `.started` and carried until the cycle ends, so a plan change mid-fast, or losing Pro under a custom goal, cannot rewrite the goal of a running fast, move its push, or flip the `completed` flag it is recorded with. 0 = not pinned (no cycle, or state persisted before the field existed); readers fall back to the plan.
- `TimerState.stagedElapsed` — persisted: a value above 0 with no fast running *is* the result screen (`screenState(at:plan:)`); without it a cold start on that screen falls back to idle and the ended fast never opens its eating window.
- `TimerState.fastEndTimestamp` — the moment the user confirmed the ending; 0 = none on the table. It must outlive the fast: `.stopped` clears `fastStartTimestamp`, and without this the result screen has no absolute time, so the window could only open from the tap instead of from the meal. Persisted with `stagedElapsed` so a window opened from a restored result screen still anchors to the meal.
- `TimerState.completedSessionsCount` — fasts that reached the goal; gates the review prompt.
- `TimerState.hasCelebrated` — persisted so relaunching mid-overtime restores the steady end-state without replaying the goal moment.
- `TimerState.eatingStartTimestamp` — 0 = no window. Window length is derived from the plan (24 − fast hours), not stored.
- `TimerState.isEating` — persisted so the window survives relaunch.
- `TimerState.streakCount` — consecutive local-calendar days with the goal reached; advanced on `goalCelebrated`, a missed day hard-resets it to 1 on the next goal. Screens show `streak.displayed(at:)`, never this raw counter.
- `TimerState.lastGoalDate` / `StreakStatus.lastGoalDate` — local day key `yyyy-MM-dd`; nil = no goal ever reached.
- `TimerState.freezeSpentMonth` — `yyyy-MM` whose protected day is spent, nil = never. One month is enough: the allowance is one per month, so the only question is whether *this* month's is gone. See `freezeCovers(_:)` for which month gets charged.
- `TimerState.streak(ownsFreeze:)` — the only thing screens should project, so the missed-day rule is applied once. `ownsFreeze` comes from the entitlement, which this substate deliberately does not hold; callers use `AppState.streak`.
- `TimerState.resolvedGoalHours(planHours:)` — the single definition of the pinned-or-plan fallback; every screen, push, record and event asks here.
- `TimerState.startTimestamp(at:)` — shifts the start back by what is staged so the count carries on. Staged time arrives two ways (a back-dated last meal, an undone ending) with the same arithmetic. One definition: if elapsed ever grows a rule (pause, segmented count), a second copy would compile with the old one and only its screen would be wrong.
- `TimerState.elapsed(at:)` — the single definition of how long the cycle has run: from the start while running (floored at 0, so a start a moment ahead of the clock reads 0, not negative), the staged value otherwise. The screen, the end-of-fast sheet, the time adjuster, the reset event and the offer tint all ask here; written out per caller, a pause or a segmented count would compile in one and be missed in the others.
- `TimerState.eatingEndTimestamp(plan:)` — the single definition of the window's close moment (countdown card, window-closed push, chained fast, last-meal seed). Meaningless while `isEating` is false. Takes a `Plan`, not hours, on purpose: *why* the window is that long is stated once in `Plan.windowHours`, and a plan cannot be confused at the call site with the goal length — `windowHours: activeGoalHours` would have compiled and produced a 16-hour window instead of 8. Pass `AppState.activePlan` (the plan the cycle runs to), not `planState.plan` (merely what is selected).
- `TimerState.eatingRemaining(at:plan:)` / `.eatingOverElapsed(at:plan:)` — the two sides of the window's close, both floored at 0: the countdown card and the count-up on the chain screen.
- `TimerState.screenState(at:plan:)` — which of the six frames the cycle is in. An open eating window shows the countdown until it closes; once closed, the chain screen (count-up + Continue fasting) holds for `closedWindowHorizon` (24h), then falls to idle. Stopped with time staged is the result screen. Running past the goal is `.goalReached` (overtime), otherwise `.active`. One definition for the timer screen and for the offer tint (`AppState.offerPhase(at:)`), which must agree with the screen it was called from on whether a window is up. Pass `AppState.activePlan`: its hours are the goal the cycle runs to.
- `TimerState.windowEndTimestamp(openedAt:plan:)` — the same arithmetic, named for a window not yet opened: the one a result screen would open from its confirmed ending.
- `TimerState.closedWindowHorizon` — one horizon for both screens that sit on a window: the window-closed chain screen and the result screen whose window was never opened.
- `TimerState.closedWindowHasLapsed(closedAt:now:)` — the single comparison against the horizon (invariant 12).
- `TimerState.droppingLapsedEnding(at:plan:)` — the result screen is persisted so iOS unloading the app does not lose it, but restored without a limit a week later "Start eating" would open a window anchored a week back. Held only while the window it would open (from the confirmed ending, as `StartEatingThunk` anchors it, under `AppState.activePlan`) is inside the closed-window horizon; past that it becomes `withoutCycle()` — the idle `.reset` leaves, minus the event. No confirmed moment (`fastEndTimestamp == 0`) = cleared as lapsed.
- `TimerState.withoutCycle()` — the single definition of idle: `.reset` and `droppingLapsedEnding` both land here so they cannot disagree about what is left (sessions count and streak kept). The pinned goal goes with the cycle: the next fast starts from the plan as it stands then.

## StreakStatus.swift

- `StreakStatus` — the run length and the day it was last extended travel together on purpose: a screen holding only the counter cannot apply the missed-day rule, and two screens would show two numbers for one state.
- `StreakStatus.ownsFreeze` — whether the install holds Pro (owns the protected day). Not stored with the streak: handed in by whoever projects it (`AppState.streak`, `TimerAction.goalCelebrated`), because the entitlement has exactly one home and the streak is not it.
- `StreakStatus.freezeCovers(_:)` — the single definition of the three freeze conditions; the projection and the reducer that spends the freeze both ask here:
  - exactly one calendar day was missed (`dayKey` two days after the last goal); two missed days are a hard reset — one protected day protects one day;
  - the install owns Pro; without it a missed day resets;
  - the month is unspent. The month charged is the month of the *missed day*, not of the goal after it: the benefit protects a day, so that day decides who pays. This is what makes a day missed on the 31st and one missed on the 1st two different months' business — the plain reading of "one per calendar month".
- `StreakStatus.freezeMonthCharged(afterGoalOn:)` — the single definition of who pays: the check, the debit in `freezeMonth(coveringGapTo:)` and the `-seedFreezeSpent` test hook all ask here. Written out in each, the rule could change in one place and still compile elsewhere — a hook charging the old month would turn the "one per calendar month" flow green while the freeze is still available.
- `StreakStatus.freezeMonth(coveringGapTo:)` — returns nil when there is no gap. Paired with `freezeCovers(_:)` so the month-picking rule is written once and the reducer reads the answer instead of recomputing which day was missed.
- `StreakStatus.displayed(at:)` — 0 once a day was missed (last goal before yesterday) unless the protected day still stands in the gap; the persisted counter is only rewritten on the next goal. The freeze is applied to what is *shown*, not only when the next goal banks it: the promise sold is that the run does not break, and a counter that drops to 0 for a day has already broken it where the user can see. Reading `ownsFreeze` as it stands *now* is all of edge 8: buying Pro during the gap day restores the run, buying a day later does not — the 24-hour window stated in days.
- `StreakStatus.lostRunFreshnessDays` — how long a just-broken run keeps being named, in days from the last goal. Needed because `count` is not rewritten until the next goal: without it someone who missed a day in March would read "that streak ended at six days" in June. Past it the state is plain "no streak", not a second kind of silence.
- `StreakStatus.display(at:)` — the single projection of the three states, so the header pill and the summary card cannot disagree. `.justEnded` carries the persisted counter, never `bestStreak`: the best run is recomputed from history rows and after an update from 1.4.4 can be *smaller* than the run actually lost — naming a number below the one the person remembers is worse than naming none.

## StreakDisplay.swift

- `StreakDisplay` — a separate type rather than `Int` + `Bool`: both surfaces pick one of three branches, and the pair spells two of them the same way (0 and "just ended at 0") while allowing a fourth that cannot happen. `.justEnded` = a run that broke inside the freshness window; `.none` = never started, or the lost run is no longer news.
- `StreakDisplay.count` / `.hasEnded` — the single definitions both surfaces read (count, drained accent, past-tense overline, the sentence) instead of unwrapping the cases themselves.
- `StreakDisplay.lastGoalDate` — kept in the projection so the history can say when the displayed number happened, without the compact header badge carrying or formatting a date.

## TimerScreenState.swift

- `TimerScreenState` — the six frames a cycle can be in, as the timer screen draws them. A domain type rather than nested in the screen: the offer tint, presented from the root, branches on it too, and a type owned by one screen would make the root depend on that screen.

## TimerAction.swift

- `TimerAction` — timestamps are injected by thunks so the reducer stays pure.
- `TimerAction.started` — `startTimestamp` already accounts for staged elapsed. `goalHours` is injected at dispatch and pinned so it stops following the plan once the fast is under way.
- `TimerAction.stopped` — `qualifiesAsCompleted` is analytics-only; completed fasts are counted on `goalCelebrated`. `backdatedMinutes` (how far behind the tap the confirmed end was placed) rides in the action because it is the difference of two moments and the tap's clock is gone by the time any middleware sees the state.
- `TimerAction.stopUndone` — undo from the result screen; `startTimestamp` comes already shifted back by the staged elapsed. Not `.started`: that pins a fresh `goalHours` and clears `hasCelebrated`, rewriting the goal the fast ran to and replaying the goal moment (session and streak day counted twice).
- `TimerAction.reset(elapsed:)` — analytics-only (running time at the reset, or the staged value). Travels in the action because middleware sees post-reduce state, where the timer is already cleared.
- `TimerAction.timeAdjusted` — `runningStartTimestamp` is non-nil only while running.
- `TimerAction.goalCelebrated` — `dayKey` (the day the goal counts toward) is injected so the reducer stays pure and a fast crossing midnight credits the day the goal was reached. `ownsFreeze` rides along for the same reason: the protected day is Pro's, the entitlement lives in `ProState`, and the timer reducer sees only its substate. Read once when the goal lands, so a later purchase or refund cannot re-decide a banked streak.
- `TimerAction.eatingStarted` — `startTimestamp` = when the window opened.

## TimerReducer.swift

- `timerReducer` — pure and synchronous; writes only to `TimerState`.
- `timerReducer` — `.stopped` — `fastEndTimestamp` is derived from the payload and state, not the clock: the confirmed end is exactly start + confirmed elapsed.
- `timerReducer` — `.stopUndone` — the exact inverse of `.stopped` and nothing more: `goalHours` stays pinned (same fast), `hasCelebrated` stays (a fast resumed from overtime must not celebrate twice), sessions count and streak untouched (written on reaching the goal, not on ending).
- `timerReducer` — `.reset` — what a cycle leaves behind is `TimerState.withoutCycle()`, shared with the launch that drops a lapsed result screen.
- `timerReducer` — `.goalCelebrated` — idempotent by design: `syncGoalMoment` is called from two places and props update asynchronously, so the guard lives here, not in the view. Reaching the goal, not tapping "End fast", completes a fast.
- `timerReducer` — `.goalCelebrated` streak — a goal the day after the last extends the run; a gap (or the first goal) restarts it at 1, unless Pro's protected day stands in the gap and the month is unspent (run carries on, month charged). Day keys sort chronologically, so a stamp not newer than the last goal (same day again, or an earlier day from a fast back-dated across midnight) leaves the run untouched: it can neither extend nor drag it backwards.
- `timerReducer` — `.eatingStarted` — clears the finished fast like reset, but into eating. `goalHours` deliberately survives: the window is the rest of the day left over by that fast, so it belongs to that goal.
- `timerReducer` — `.eatingEnded` — end of the cycle: no goal is held.

## Buttons.swift

- `labelInset` — the horizontal room inside every button shape: English labels never reach the corner radius, but German and Ukrainian ("Zurücksetzen", "Продовжити піст") are half again as long and would sit flush against the rounded edge.
- `SecondaryButton.minWidth` — next to a primary, the secondary sizes to its own label (from `minWidth`, widening for longer locales) and leaves the rest to the primary. nil = fills its container (sheets, where it is alone in the row). Content-sized only when a floor is given: the nil proposal of `fixedSize` resolves the frame to the label width within `[minWidth, maxContentWidth]`.
- `SecondaryButton.maxContentWidth` — caps the content-sized width so a very long secondary label cannot crowd the primary out; past it the label scales down.
- `TertiaryTextButton` — text-only, for an exit the card offers but does not want tapped by accident; it ranks below the bordered secondary, so must not look like one. Wraps to a second line before it shrinks, and shrinks no further than 0.94: at the xxLarge ceiling the Ukrainian and French labels outgrow the ~267pt the footer column leaves, and a scale floor alone would take them below the size the reader asked for.
- `SheetPrimaryButton` — not `PrimaryButton` with another number; three properties differ, each for its own reason:
  - no `minimumScaleFactor`: a label wider than ~153pt at xxLarge would render *below* base size under a 0.7 floor — text turned up gets smaller type on the one control that matters, and no truncation hunt sees it. It wraps and the shape grows;
  - `minHeight`, not `height`: a box measured off the English mock-up overflows in German, and that looks like overlap, not a clip;
  - no drop shadow: these sit on a sheet card, not over a scrolling screen; the footer's lifting shadow only muddies the edge here.
- `QuietActionButton` — the reversible action of consequence sheets ("Keep this fast", "Open that fast"). Quiet material, not a bordered secondary, so it does not read as a third option: it is the named form of closing the sheet (what the scrim tap does). Last element, no chevron, full width.

## ConsequenceInset.swift

- `ConsequenceInset` — the app's third register next to prose and buttons: "this will cost you". One component for the end-of-fast sheet (mode A, card with no scroll) and the result-screen footer (mode C, pinned outside the scroll), so the two cannot drift into two dialects of one sentence. Rules that are not stylistic:
  - never tappable and never looks it: no press state, no chevron, radius too small to pass for a card;
  - `minHeight`, never fixed height: measured 66pt at the default size and 76pt at the xxLarge ceiling (worst case Japanese, line box 25.94pt vs Hanken's 22.53pt); an English-measured box overflows in German and looks like overlap;
  - no `minimumScaleFactor`: at the ceiling a 0.7 floor renders below base size — text turned up, type turned down. It wraps.
- `ConsequenceInset.messageDelay` / `ConsequenceInset.messageRise` — the message rises after its surface settles, never over a transition. Values come from 1.5.0's accepted motion and are two on purpose: wait and travel may be retuned apart.
- `ConsequenceInset.body` — only the message moves; the fill is drawn with the surface and never animates. The wait is `.delay` on the curve, not a scheduled job, so no timer outlives a surface closed during those 0.42s.

## EatingWindowCard.swift

- `EatingWindowCard` — no ring, no phases: the window is a calm pause between fasts. `remaining` is seconds until the window closes; `closesAt` is the hour eating has to end by. The countdown answers "how long left", the caption "until when" — the question people plan a meal around.
- `EatingOverCard` — the same card counting UP since the window closed (`sinceClose`, seconds): that time already belongs to the next fast once the user continues.
- `WindowCard.overlineText` — the live dot is inline content of the label, not a sibling: it mirrors to the right of the text in Arabic with no left/right rule, stays on the first line box when the label wraps instead of centring on the block, and is sized by the label font so it grows with Dynamic Type. The spacer is `Text(verbatim:)`: a plain `Text(" ")` is a localisable literal and becomes a one-space catalog key with ten empty locales nobody can fill or retire.
- `WindowCard` overline — "WINDOW CLOSED" is "FENSTER GESCHLOSSEN" in German and at large sizes runs out of the circle. It gets the chord width at its own height (narrower than the caption's, being nearer the top) and wraps in a fixed two-line slot so countdown and caption stay put.
- `WindowCard` caption — the circle is a hard boundary and the caption is the locale-variable line ("Fasting so far" is three words in English, four in Ukrainian): chord width at its height minus a margin, wrapping inside. Fixed two-line slot so the countdown does not move between locales — the card must not recompose itself per locale.
- `WindowCard` halo — soft accent halo, wider and dimmer than the drop shadow, pulsing slowly while the window is open.

## FooterCard.swift

- `Stat` — the value wraps (up to 3 lines) instead of one clipped line: a column is an equal fraction of the card and SwiftUI does not clip an overflowing `Text`, so a single scaled line draws across the hairline divider into its neighbour (de, ja, ko overtime stats at the largest allowed size). A locale that fits only by being shorter is not to be relied on. Lowering `minimumScaleFactor` instead would shrink below the size the reader asked for; wrapping only changes the line count where one line would overflow.
- `ActiveFooterCard.isEndFastEnabled` — false while the correction sheet this button opens is up. The button stays under the sheet's scrim, and left live it reads as the way to confirm the ending, while a tap there is outside the card and closes the sheet. `GoalReachedFooterCard.isEndFastEnabled` is the same button and sheet.
- `GoalReachedFooterCard` — the fast is still running: "End fast" ends it, "Reset" discards it (behind a confirm).
- `EatingFooterCard` — no stats: the countdown above is the hero and already names the closing hour. The window lasts hours, so it gets its own way into history: the fast that just closed is still "today's" and the link opens straight to it; `lastFast` is nil only until the first record exists.
- `EatingFooterCard` "done eating" — a quiet `TertiaryTextButton` that only asks: ending early also drops the closing push, and a full-width bordered button right under "Start fast" gets tapped as "close this screen".
- `EatingOverFooterCard` — "Continue fasting" chains the next fast from the Last-meal time; no stats, the count-up is the hero.
- `CompleteFooterCard` — mode C of the consequence genre, pinned above the home indicator outside the scroll: every point it grows comes out of the scrolling middle, so the consequence budget is one sentence — never none, never two — and no other content may be added; the history row is the one navigation it carries (next point).
- `CompleteFooterCard` history row — in the card, not in the scrolling middle: the tail of the middle sits under the card at rest (on a 375pt screen there is no free band above it), so a row there is invisible while its accessibility bounds still report it on screen and a tap lands on the card. First, as on `EatingFooterCard`, not last: at the bottom a navigation with no consequence would read as the final step, right under the only reversible action. Its ~32pt come out of the scrolling middle: on SE the card's top edge crosses the counter at rest — the FASTED stat repeats the number, and the middle scrolls. Accessibility id `timer.savedToHistory`.
- `CompleteFooterCard.consequence` — already arbitrated by the path the fast ended on; which sentence is true is a fact about the fast, not the footer.
- `CompleteFooterCard.onSkip` — back to idle without opening the window. Not labelled "Reset": here that promises to discard a fast already in the history.
- `CompleteFooterCard` resume — the undo sits on the same quiet material as the sentence explaining it (warning and way out visibly one family). 50pt tall so the only reversible control is not the one thing below the HIG minimum, and because rank resting on grey does not survive Arabic, where grey semibold reads stronger. No chevron (it goes nowhere); no lead-in like "Ended by mistake?" — that frames the tap as a confession.
- `View.endFastAvailability(_:)` — the one place the unavailable look of "End fast" is defined, so the two footers cannot drift. `.disabled` alone is invisible: the button paints its own fill, which no system style dims.

## GoalMomentView.swift

- `GoalMomentView` — a pure view: the parent owns the animation values so the one-shot moment plays only on a genuine live crossing, and relaunching mid-overtime restores the settled end-state with no replay. `sealScale`: 0 hidden, 1 full; `sweepAngle`: degrees, 0...360.
- `GoalMomentView.sealDiameter` — shared with `PhaseRing`, which opens its arc around a seal this size; the seal's place is a real break in the ring, not a disc painted over it.
- `GoalMomentView.body` — LTR pin — same reason as `PhaseRing`: the sweep is placed by `rotationEffect`, whose angle RTL negates; unpinned, the arc meant to start at twelve o'clock starts half a turn away from its ring.
- `GoalMomentView.halo` — the teal glow behind the ring is the "glowing ring" of the dark theme.

## HistoryLink.swift

- `HistoryLink` — the chevron is the whole navigation affordance.
- `HistoryLink` target — glyph-sized on purpose: both rows sit in a footer card right above other controls, and an invisible hot area under a neighbouring control lets a tap a few points low land on the other row.

## LastMealPill.swift

- `LastMealPill` — idle entry to the log-meal flow; when a past time is chosen, `subline` says what the fast will count from.

## MealScaleRibbon.swift

- `MealScaleRibbon` — a real timeline longer than the screen under a fixed marker; midnights are drawn on it, so "I ate at ten last night" is a scroll past one marked line rather than a separate date control. Geometry lives in `MealScale`; this file draws it and reads the finger.
- `MealScaleRibbon.nowMinuteOfDay` — injected clock: the midnight rules are the one calendar-aware part and need "now" to be placed.
- `MealScaleRibbon.offset` — continuous: the strip slides under the finger while the *value* clicks tick to tick.
- `MealScaleRibbon.lastTranslation` — the strip moves incrementally because the gain on each delta changes with finger speed; an absolute anchor + translation cannot carry that.
- `MealScaleRibbon.tickBaseline` — layer constants — from the handoff, measured up from the block's bottom edge where the ticks stand.
- `MealScaleRibbon.labelRowTop` — 43 in the handoff table, 40 as drawn: the mockups put the label row 3pt higher, which keeps labels clear of the tick line.
- `MealScaleRibbon.grabSlackTop` / `MealScaleRibbon.grabSlackBottom` — the ticks are 60pt tall, and a gesture on exactly that box ignores a thumb landing ten points high with no feedback. Uneven because the room is: above is the readout's free gap; below is the sheet's tight gap and the 44pt collar of "Set exact time", and reaching into it would swallow taps meant for the button. The grab zone is an overlay, not a taller frame, so it can overflow without moving any measured spacing; overlays centre on the parent, so the half-difference is offset back by hand.
- `MealScaleRibbon.dirSign` — +1 when the past runs left (LTR), −1 in Arabic: the ribbon mirrors with the text, so "drag back" and "read back" are one direction.
- `MealScaleRibbon.body` — tick labels — `.dynamicTypeSize(.large)`: markings, not prose; at large sizes they would collide, and everything they say is repeated full size in the readout. The single deliberate Dynamic Type exemption in this sheet.
- `MealScaleRibbon.body` — accessibility — the adjustable action gives VoiceOver swipe up/down, one snap step of the current band each.
- `MealScaleRibbon.body` — external value sync — chips and the exact-time picker move the value from outside and the strip rides to meet it; skipped mid-drag, where the finger is in charge.
- `MealScaleRibbon.drag(width:)` — warms the taptic engine before the first step, otherwise that click arrives late and the track starts ragged. Release: a hard flick coasts as far as the system's throw projection implies and decelerates into the settle ("spin harder, get there faster" across a one-minute scale; landing is clamped to the strip, so no ceiling is needed). Below a deliberate-placement speed the lift has NO inertia, so a careful set stays on the minute the finger left. Longer coast = longer settle, so a fling decelerates like a wheel while a nudge stays crisp.
- `MealScaleRibbon.scrubGain(speed:)` — velocity-adaptive gain (pt/s): a slow, aiming finger gets 0.45 so a 30-minute tick takes real travel and can be aimed; a committed sweep gets 1.0 so twelve hours stays one gesture; linear in between so there is no gear change. Flat sensitivity cannot do both: at 30 minutes per 6pt the aiming end is twitchy.
- `MealScaleRibbon.rubberBand(_:)` — capped at 40pt of give: enough to feel the wall without reading as a broken scroll.
- `MealScaleRibbon.report(fast:)` — haptic throttle — no taptic queue behind a fling: above ~900pt/s steps arrive faster than the engine separates them and it becomes a buzz.
- `MealScaleRibbon.marker` — the stem stands on the tick line, 34pt tall, dot on top. Measured off the mockups, not the handoff table (§4), which puts both 4pt lower and leaves the stem floating.
- `MealScaleRibbon.draw(in:size:)` — draws a little past the edges so a tick never pops in mid-slide. The strip snaps every minute, but minor marks are thinned to every fifth minute (a mark per minute is a grey smear at this pitch); the value still lands on any minute. The hard end of the domain is drawn as a wall, not faded out. A midnight rule is local midnight `daysBack - 1` days ago as a distance; its day name sits on the older side of the rule (it labels the day the rule opens — the other side in RTL).

## NextPhaseChip.swift

- `NextPhaseChip` — coloured by the NEXT phase (handoff-derived colours). `StaticPhaseChip` (no countdown) is the overtime state's autophagy chip.

## PhaseRing.swift

- `PhaseRing` — a 280pt ring whose arc is a smooth gradient of every phase passed, tipped by a head dot in the current phase colour. When complete, the gradient loops through all five phases and the ring holds at 100% for the whole overtime — no growth, no head dot. `progress` is 0...1 of the goal.
- `PhaseRing.sealDiameter` — 0 = no seal. Track and looped arc are trimmed open around the seal, 2pt clear of its edge: an opaque disc cannot match the screen's gradient backdrop, and on the 12h geometry the arc would read as running through the check. The track is opened too, so no sliver peeks out beside it.
- `PhaseRing.showsHeadDot` — false for an ended fast: on the result screen a breathing dot reads as a timer still running over a card that says the fast is over.
- `PhaseRing.centerRadius` — the stroked circle's path radius is diameter/2, so the head dot rides there to sit centred on the line, not inset by half the stroke.
- `PhaseRing.sealGap` — measured on the centreline: half the seal + clearance + half the stroke, because round caps reach that far past the trim point.
- `PhaseRing.body` — progress arc caps — flat, like the design's conic arc: a round start cap would bleed the gradient's wrap colour (ketosis) onto the gold Fed start; the head dot covers the flat leading edge.
- `PhaseRing.body` — LTR pin — progress runs clockwise from twelve in every locale (the handoff: rings do not mirror), but RTL treats the arc and the dot differently: `rotationEffect`'s angle is negated (−90° becomes +90°, start at six o'clock) while `offset(x:)` is mirrored. Unpinned they disagree by half a turn — Arabic draws an arc in the bottom-left with the marker at ten o'clock. Same pin as the paywall spinner.
- `PhaseRing.progressGradient` — quarter-boundary stops up to the head, tipped with the current phase colour. `loopedGradient` — full-circle 6-stop loop so the seam at the top blends.
- `PhaseRing.headDot` — position animates on the wrapper and the breathing pulse on the inner `BreathingDot`, so the two animations do not fight.

## PhaseTimeline.swift

- `PhaseTimeline` — current phase fills by its real progress within the phase (`currentFill`, 0...1), passed 100%, future 0%.
- `PhaseTimeline.showsLabels` — the history detail panel reuses the bars without labels: the phase is already named in the line above.

## RingCenter.swift

- `RingCenterActive.elapsedNumerals` — big H:MM and dimmed :SS in one baseline-aligned run, so the readout scales as a unit (`minimumScaleFactor`) and never touches the ring on narrow devices or at two-digit hours.
- `RingCenterActive.body` — overline tracking — `.overlineTracking(1.9)` is ~.16em at 12pt (LTR only).
- `overtimeLabel(_:)` — M:SS under an hour, H:MM past one.
- `RingCenterGoalReached` — the fast keeps ticking past the goal, so numerals stay live while a pill shows how far over the user is.
- `RingCenterComplete` — the check is the app's only picture of "the goal was taken", so it is drawn only for a fast that took it; a fast ended at minute five must not get the same mark. A fast that fell short keeps label and numerals; the card below already says it does not count, so nothing repeats it here.
- `RingCenterComplete.goalReached` — asked of `PhaseProgress`, where the predicate lives, not recomputed from `elapsed`.

## SegmentedControl.swift

- `SegmentedControl` — shared by the plan editor and the quick last-meal chips. The chips split the track into equal thirds, so a title outgrowing its third has nowhere to go: without a line ceiling it wraps and grows the control, which no truncation hunt sees. The scale floor is what makes the ceiling safe — "ساعة واحدة" and "1 Stunde" at the xxLarge cap squeeze rather than lose their tail.

## StreakBadge.swift

- `StreakBadge` — doubles as the way into history: the badge is the streak compressed, the history screen the same streak unfolded. Tapping "12 days" answers "twelve days of what?", so the app needs no history tab and stays single-screen. The ring fills toward the next milestone (3/7/14/30/60); the chevron is the only navigation hint a pill this small can carry.
- `StreakBadge` — no unit word beside the number — pluralising a 12.5pt word across ten locales (six categories in Arabic, four in Polish) is not worth one word; it lives where there is room: the summary card and the VoiceOver label.
- `StreakBadge` — three states, none carrying a word — a word turns the pill from "my number" into a screen name and costs width the header does not have: the text budget on the rung that still carries the Pro capsule is 72.0pt at base size, and the shortest two-word streak candidate runs 78pt in all ten locales. A just-broken run keeps its number, drained of accent; a pill with nothing to count carries the history glyph. The glyph is a fixed 17pt box Dynamic Type never grows, so the state costs the same in every locale and size.
- `StreakBadge.display` — projected once in `StreakStatus.display(at:)`, so pill and summary card cannot disagree. `days` reads `display.count` — one definition, two surfaces.
- `StreakBadge.accessibilityLabel` — says in words what the pill cannot spend width on: whether the number is a run in progress or one that ended.
- `StreakBadge.progress(_:)` — a streak past the last milestone stays full.
- `StreakBadge.body` — ended-run arc — keeps its arc, loses the accent: `faint` says "this was progress" without reading as progress being made. The accent means "your progress now"; lending it to a finished run would be the app disagreeing with itself.
- `StreakBadge.body` — ring slot — the 22pt slot holds an 18pt ring; the stroke is centred on that circle, so it reads 20.2pt across as in the mockups.
- `StreakBadge.body` — ring LTR pin — on the ring alone, not the row (the counter still follows reading direction): RTL negates the −90° that starts the arc at twelve and would start the Arabic arc at six.
- `StreakBadge.body` — `Text(verbatim: String(days))` — `Text("\(days)")` takes the `LocalizedStringKey` path and lets the locale format the integer (Arabic-Indic "١" next to the Western digits of the history card). `String(_: Int)` is always Western like every number in the app; same as `HistorySummaryCard`'s counter.
- `StreakBadge.body` — history glyph (`history-arrow`) — a clock inside a counter-clockwise arc: time turned back. Fixed 17pt, never scaled — that constancy is why the state is free in every locale. Does not mirror in RTL (a clock runs clockwise everywhere; a mirrored return arc reads as fast-forward); only the pill and chevron mirror. The ring's slot carries 2pt padding the glyph does not, so the glyph takes the difference in its leading inset instead of widening the pill.
- `StreakBadge.body` — `lineLimit(1)` + `fixedSize` — the same pair `TimerHeader.pill(withName:withPencil:)` carries, for the same reason: inside `ViewThatFits` a candidate reports the width it could squeeze to, so without it the widest rung always "fits" and the badge pays (a clipped digit, or in Arabic nothing beside the bare ring and chevron). `lineLimit` stops wrapping, `fixedSize` makes the reported width honest, so the ladder drops the plan name (the header's first thing to give) instead of crushing the badge. No scale factor, deliberately: yielding nothing means not shrinking either.
- `StreakBadge.body` — `.frame(height: 44)` — the pill is 34pt; the tap target is a full 44.

## TimerHeader.swift

- `TimerHeader.streak` — live number, the number a broken run left, or nothing; no records and nothing to count = no pill.
- `TimerHeader.showsPro` — whether the Pro entry belongs on screen is decided by the flow (verified `free` entitlement, not in the goal moment); the header only lays it out and gives it up first when width runs out.
- `TimerHeader.body` — give-way ladder — a decision, not convenience: the plan name goes first (the ratio already says it), then the pencil, then the Pro control leaves whole; the streak badge yields nothing — not its word, not its presence. A badge stripped to a bare ring with a chevron no longer works as a control; doing that at accessibility sizes to keep Pro would fix one thing by breaking its neighbour.
- `TimerHeader.body` — pencil rung — exists because the row above has no slack: at 375pt, the largest type and the longest History word ("Historique") it takes 327 of 327pt, and a fifth glyph in the ratio (`14:10`, any custom goal of 10-14h) costs one tabular digit — pill 79.5pt → 89.5pt — and the row would fall past the Pro control to the last rung. Dropping the pencil takes the pill to 69pt. Squeezing the pill's padding 13 → 8 frees only 10pt (back onto the same edge) and breaks a spacing the mockups pin.
- `TimerHeader.body` — Pro rung — not a rung to spend on a hair's width: the control exists because of an Apple rejection and raises the event for entering the offer from the main screen, so no locale may lose it while anything cheaper is left.
- `TimerHeader.body` — whole-row measurement — a nested `ViewThatFits` inside the pill is measured with an unspecified width and always reports its widest candidate, which would drop Pro *before* the plan name — the ladder upside down.
- `TimerHeader.body` — last rung — with `showsPro == false` it repeats the one above, which keeps the ladder one list: a conditional inside `ViewThatFits` collapses into a single candidate.
- `TimerHeader.row(withPlanName:withPencil:withPro:)` — plan name — context the ratio already carries ("16:8" + pencil is the whole control); when width runs out (narrow screen, large type, a long name like "Tägliches Fasten") it steps aside rather than wrapping or shrinking below what the ratio beside it says. Measured per render, so a roomy header keeps it.
- `TimerHeader.row(withPlanName:withPencil:withPro:)` — streak pill presence — nothing to open before the first fast lands; the pill appears with the first record. A live streak counts too: otherwise emptying history mid-fast shuts the door for the rest of the fast and the app tells someone on a two-day run they have no streak.
- `TimerHeader.row(withPlanName:withPencil:withPro:)` — settings glyph — the sheet is the app's own document (Pro, privacy, sources): `doc.text` would promise a paper; `info.circle` says "about this app" without promising a menu that does not exist. The circle stays 34pt with a 44pt target like the streak badge: with a second small control beside it, a sub-44 target turns near misses into systematic wrong taps.
- `TimerHeader.proButton` — furniture, not a shopfront: no icon, no gradient, not the accent (the accent means "your progress" — ring, seal, halo — and lending it to the one commercial element paints selling in the colour of achievement). Told apart from its filled neighbours by material and word: `surfaceQuiet` is the design system's "has weight, not an action" rank, a step firmer than the green wash of the icon circle and plan capsule. An outline would also work but, as the one unfilled thing in a row of fills, reads as unfinished.
- `TimerHeader.proButton` — `Text(verbatim: "PRO")` — load-bearing: a bare literal takes the `LocalizedStringKey` path and the next catalog sync lifts the mark into a new key across ten locales, for a label not translated anywhere (same as `StreakBadge`'s digits). Line limit and scale factor never fire on three Latin glyphs; they make a future translated label squeeze instead of truncate.
- `TimerHeader.proButton` — PRO wordmark — caps at 12pt / 600 with .16em tracking is what the handoff calls the premium work; the spacing does it, nothing is spent on crown, gradient or accent. The spoken label keeps a screen reader from spelling the letters.
- `TimerHeader.proButton` — `.tracking(12 * 0.16)` — plain `tracking`, not `overlineTracking`: that one drops spacing in Arabic and Korean because it is for text set in those scripts, and this is three Latin glyphs everywhere. The plan editor's badge uses the flat modifier for the same reason at a quarter of the value (a badge in a row of text, not a mark). The tracking trails the last glyph exactly as the handoff's render does.
- `TimerHeader.proButton` — `theme.ink` on `surfaceQuiet` — 12.2:1 light, 13.7:1 dark: clear of the 3:1 a control owes. No new shade enters the header; the fill is a system rank also drawn for the reversible-action surfaces of the consequence sheets, which is why it lives in the theme (here its only caller).
- `TimerHeader.proButton` — capsule size — a real capsule of the row's height, pinned rather than scaling: a label growing with text size while both 34pt neighbours do not becomes at xxLarge the emptiest and largest control in the row (reads as a placeholder), and below that a pinched lozenge. The handoff's width arithmetic does not hold (its dropped border was an overlay and cost no width): on 375pt the control is 49pt at default size and 54.5pt at xxLarge; in the tightest reachable state (French, largest type, two-digit streak beside a 14:10 plan) the row keeps its rung with 55.5pt of slack. Height is clamped, not floored — safe while `AppFlowView` caps dynamic type at xxLarge (the mark's line box is well inside 34); raising that ceiling needs this re-checked.
- `TimerHeader.proButton` — tap target — fill keeps its height, target is 44 and a rectangle, unlike the streak badge: that one is wide enough that a capsule target costs nothing, this one is barely wider than tall, so capsule corners would eat most of the 44. The settings circle does the same; the 8pt row spacing keeps the two rectangles apart.
- `TimerHeader.proButton` — accessibility — "Pro" alone tells a blind user nothing, so the label is the product's whole name; the hint is the shared one of every gated control (third consumer).
- `TimerHeader.pill(withName:withPencil:)` — `fixedSize` makes the choice honest: without it a candidate reports the width it could squeeze to, and the wider one always "fits" by breaking words.
- `TimerHeader.pill(withName:withPencil:)` — pencil — the last thing the pill gives before the row starts costing controls. A hint that the ratio is editable, not the way in (the whole capsule is the button), and an unlabelled SF symbol adds nothing to the spoken label: dropping it costs a sighted user a cue and a VoiceOver user nothing.

## EndEatingConfirmSheet.swift

- `EndEatingConfirmSheet` — a bottom sheet, like `ResetConfirmSheet`, because on iOS 26 `.confirmationDialog` renders as a popover that hides the `.cancel` button. It exists because the footer button sits right under "Start fast", where a short label reads as "close this screen", and ending the window also drops its closing push — a mis-tap costs the one reminder the window was there to deliver.
- `EndEatingConfirmSheet.body` — same structure as `ResetConfirmSheet`: the stack always exists, only its children come and go.
- `EndEatingConfirmSheet.sheet(bottomInset:)` — "Keep open" button — last on purpose: the finger that just tapped the footer sits low, and a second tap from it must land on the safe action.

## EndFastSheet.swift

- `EndFastSheet` — four mutually exclusive cards, one component. Mode A of the consequence genre: not in a ScrollView, with 583pt to live in on an iPhone SE 3, so every new line REPLACES an existing one: the near-goal line takes the hint's slot, the refusal takes the whole card. Two non-stylistic rules across all states:
  - no fixed heights on text — every block is a `minHeight` with slack; an English-measured box overflows in German and looks like overlap, not a clip;
  - no `minimumScaleFactor` — at xxLarge a label wider than ~153pt renders below base size under a 0.7 floor; text wraps and the block grows.
- `EndFastSheet.now` — passed in, not read here: a view that reads the clock cannot be rendered twice and compared.
- `EndFastSheet.card` — the whole card cross-fades between states and nothing animates its layout, which is why replacement is a hard rule: no animation can absorb a height change.
- `EndFastSheet.pickerCard` — "Keep this fast" — last, no chevron, and it repeats the noun of the line above so the pair reads as sentence and answer, not options three and four. The named form of closing the sheet (what the scrim tap does).
- `EndFastSheet.consequenceInset(_:)` — the genre lives in `ConsequenceInset`, shared with the result screen's pinned footer so the two cannot drift.
- `EndFastSheet.chipRow` — chips keyed by position, not label: two presets can be clamped onto the same moment near the edge of the reachable range, and identical labels would collapse three chips into two. Accessibility ids are positional for the same reason: labels are translated into ten languages and can coincide, so a flow naming a chip by text names a moving target.
- `EndFastSheet.isOnGoalEnd` — true while the exact-time value still sits where the sheet put it (the moment the goal ran out); the caption then says "the time your goal was reached" rather than a bare clock time.
- `EndFastSheet.refusalCard` — header — its own title: reusing "When did you eat?" over a body that is no longer a picker describes something not there. Body budgeted for four German lines by minimum height, never fixed: a fifth line grows the block instead of running under the actions.
- `EndFastSheet.refusalCard` — exits — live, nothing dimmed: a silently inactive control is the unsaid refusal this state replaces. When the clash is on the start, "pick another time" is dropped (it could only loop back here) and removing the old record leads as the one real way out; when a re-pick could still clear it, both stand, re-pick first.

## LastMealPickerSheet.swift

- `LastMealPickerSheet` — the key flow: back-dating a fast; two thirds of everyone who starts a fast comes through here. The question answered is "how long ago", so that is the control: one ribbon over the whole domain, four presets for common answers, and the clock time demoted to what follows from the choice. No date control: the day is a consequence, not an input. The readout sits *above* the ribbon: a finger on the ribbon covers the bottom third of the sheet, exactly when the value matters.
- `LastMealPickerSheet.nowMinuteOfDay` — injected by the flow: the ribbon's midnight rules need it, and the reducer must never read a clock.
- `LastMealPickerSheet.overline` — set only when opened from the closed eating window, where the app, not the user, put the value there.
- `LastMealPickerSheet.selectedChip` — −1 = none.
- `LastMealPickerSheet.sectionGap` / `LastMealPickerSheet.tightGap` — the card's vertical rhythm in two values (five gaps in one card is five decisions nobody can hold; density is read off this stack, not off the ribbon). `section` separates things answering different questions (heading, shortcuts, value, strip); `tight` binds the strip and the two buttons under it. Gaps are measured to the *boxes*, so the 44pt collar of "Set exact time" counts as its edge.
- `LastMealPickerSheet.body` — bottom placement — the card sits 20pt off the physical bottom edge, as drawn: Confirm still clears the home indicator by 30pt, and honouring the safe area on top would push the sheet a third of the way up.
- `LastMealPickerSheet.card` — title — no explanatory subtitle: it would say in prose what the readout says in the value, cost a text block on a dense card, and wrap in German. `Sheet.backdateHint` stays in the catalog with its ten translations: the string is not wrong, only its place, and a deleted key is ten translations to buy back.
- `LastMealPickerSheet.card` — "Set exact time" — a 13pt collar lifts the one-line link to a 44pt target, and that target is layout: the handoff measures 12pt above and 6pt below to the 44pt box, not the text. It is a bordered capsule with a clock glyph because as faint text the deliberate way to a specific time read as fine print and got missed.
- `LastMealPickerSheet.chips` — not an equal four-way split: "Last night" is one word in English and three in Polish, and equal shares would crop it; the row wraps (`ChipFlowLayout`). Selected chip uses `strokeBorder`, not `stroke`: a 1.5pt border on the centre line would make it 1.5pt taller than its neighbours.
- `ChipFlowLayout` — each chip takes its label's width and the row breaks when the next no longer fits. No manual mirroring: SwiftUI resolves a Layout's placement against layout direction, so an Arabic row fills from the right on its own.
- `LastMealPickerSheet.readoutBlock` — the clock time leads: a person who "started at 19:50" thinks in the time; the duration is the caption for whoever reads the strip that way. `.numericText()` rolls only the changed digits; its duration is kept under the ribbon's 45ms haptic throttle so a fast scrub lands instead of queueing animations. Top padding 2: the handoff's 5pt is a CSS margin between line boxes, and Bricolage's descender space covers most of it. Combined into one accessibility element so VoiceOver does not announce duration and clock time as unrelated facts.
- `LastMealPickerSheet.exactTimeSheet` — `DatePicker(String(), …)`, not `""`: see `PlanEditorSheet` picker.

## PlanEditorSheet.swift

- `PlanEditorSheet` — top-anchored overlay card with a dimmed backdrop (tap-out closes). No eating-window clock hours on the card: the app runs on anchors, so clock hours here would be invented; duration is the only true value and is stated once, in the value line. Custom is its own row under the control, not a fifth segment: a segmented control promises immediate choice, and a segment that opens a sales screen breaks that promise half a centimetre under "Tap to change".
- `PlanEditorSheet` — Pro gating — without Pro the picker still opens and turns; only confirming is locked, and confirming opens the offer: a decision to buy should not be made from a description.
- `PlanEditorSheet.isPro` — gates confirming a custom length only; the picker ignores it.
- `PlanEditorSheet.onSelect` — reports the plan by hours, not segment index: segments are the four presets, and a custom plan has no place in that list.
- `PlanEditorSheet.onDone` — carries the length on screen as an argument because until the gate lets it through it is not in the store.
- `PlanEditorSheet.draftHours` — nil = "whatever the store says". The wheel turns a draft, not the plan: dispatching on every detent would write a length before the entitlement check, so a free user who spun to 17, met the offer and walked away would keep a plan the app will not fast to — in the header, across cold starts, and reported to GA4 as a confirmed custom plan.
- `PlanEditorSheet.shown` — draft while the wheel owns the value, store plan otherwise; every part stating the plan reads this one value so value line, trailing number and lit segment cannot disagree.
- `PlanEditorSheet.canConfirm` — asked about what is on screen at the moment of confirming.
- `PlanEditorSheet.card` — segment selection — a custom plan lights no segment: 16:8 lit next to a 17h value would be a stale answer, not a quiet one. Picking a preset clears the draft so the store's answer is shown again; a preset is the one path that writes a plan straight through. The control dims to 0.75 while the picker owns the value.
- `PlanEditorSheet.card` — Done accessibility hint — on the one branch where the tap opens the offer the label cannot say so without lying on every other branch; the hint names the destination, and the PRO badge on the custom row is what survives hints being switched off.
- `PlanEditorSheet.valueLine` — "16h fast · 8h window": two durations, no wall clock. The number is display type and the rest body, so two views, never one string.
- `PlanEditorSheet.trailing` — lock, value or chevron share one trailing box so the row does not resize when Pro turns on.
- `PlanEditorSheet.trailing` — PRO badge accessibility — caps trigger letter-by-letter speech (Korean VoiceOver reads "피-알-오"), so it speaks the product name like the header control. Not hidden instead: it is the channel that survives hints being off.
- `PlanEditorSheet.trailing` — `chevron.forward`, not `chevron.right` — a disclosure indicator means "on ahead", which is leftward in Arabic; `chevron.right` would point back into the label after mirroring.
- `PlanEditorSheet.hourPicker` — `Picker(String(), …)` — not `""`: a bare literal here is a `LocalizedStringKey` and the extractor writes a catalog key made of nothing (ten empty locales nobody can fill or retire). Deleting it by hand does not hold — it comes back with the next build unless every emitter uses this overload. The `StringProtocol` overload takes the same empty label and is not extracted; the wheel hides it either way.

## ResetConfirmSheet.swift

- `ResetConfirmSheet` — replaces `.confirmationDialog`, which on iOS 26 renders as a popover hiding `.cancel` and leaving only the destructive action. Two explicit actions: confirm the reset, or keep fasting.
- `ResetConfirmSheet.body` — the stack always exists and only its children come and go: inserting the stack hands SwiftUI's default opacity transition to everything inside, and the fade swallows the sheet's travel. Separate `if`s so scrim and sheet insert independently, each on its own transition. The real bottom inset is read so the card lifts consistently: on home-indicator devices the inset is the gap, on home-button ones (inset 0) a fixed minimum keeps the button off the edge (`max(22, 40 - bottomInset)` keeps the total ~40pt). Full opacity during travel: a solid thing that was waiting below the edge, not one materialising mid-flight. `.allowsHitTesting(isOpen)`: the GeometryReader fills the overlay even when closed and would swallow taps meant for the timer.
- `ResetConfirmSheet.sheet(bottomInset:)` — confirm button — destructive, and unlike `DeleteFastSheet` it gets no slab of its own colour: in a confirmation sheet the fill belongs to the safe action, so this one is red and plain. Identifiers follow actions, not styles — `reset.confirm` stays on the reset.

## StreakMilestoneSheet.swift

- `StreakMilestoneSheet` — "N days in a row" at 3/7/14/30, once per threshold after the goal moment settles; calm editorial, one close button.
- `StreakMilestoneSheet.body` — same overlay mechanics as `ResetConfirmSheet` (always-present stack, independent scrim/sheet transitions, real bottom inset with a home-button minimum, full opacity in travel, hit testing only while open).

## AdjustTimeThunk.swift

- `AdjustTimeThunk` — while running, re-bases `fastStartTimestamp` so the count keeps ticking from the adjusted value.

## CelebrateGoalThunk.swift

- `CelebrateGoalThunk` — stamps the day the goal was *crossed* (`Clock.goalDayKey`), not the day the thunk ran, so a back-dated fast whose goal landed before midnight credits the same day the history screen does. The reducer is idempotent, so a second call (relaunch, scene-phase replay) changes nothing.
- `CelebrateGoalThunk.execute` — start guard — thunks run asynchronously: the fast can end between the frame that saw the crossing and this line, and a start of 0 would stamp 1970.

## ContinueFastingThunk.swift

- `ContinueFastingThunk` — chains the next fast from the window-closed screen, starting from the Last-meal control's time (seeded to the window close). Reads the clock and dispatches a pure `.started`, which also closes the window.
- `ContinueFastingThunk.execute` — `minutesAgo` — both branches end in one distance turned into a start by one function, so the "never in the future" floor cannot exist on one path and be missing on the other. Nothing chosen = the moment the window closed.
- `ContinueFastingThunk.execute` — `.started` goal — the plan as it stands now, not the one the window it chains from was measured with.

## ResetFastThunk.swift

- `ResetFastThunk` — reset is not a completed session: no review prompt.
- `ResetFastThunk.execute` — `now` / elapsed — read here and asked of `TimerState.elapsed(at:)`: this is the last point where elapsed exists. `fast_reset.elapsed_minutes` separates a start-time correction (minutes) from giving up (hours).
- `ResetFastThunk.execute` — `ProAction.autoOfferCancelled` — reset out of the complete state means "this fast was rubbish"; selling a lifetime purchase on it would spend the install's one show on its worst second. Suppression, not consumption: the flag is untouched and the next qualified fast arms a new show.

## ResumeFastThunk.swift

- `ResumeFastThunk` — undo of "End fast" on the result screen. End fast stays one tap; this is the way back from a mis-tap, which a confirm sheet would have taxed every intentional ending to prevent. Not `StartFastThunk`: that pins `goalHours` from the current plan and would rewrite the goal the fast ran to. Undo restores, it does not begin.
- `ResumeFastThunk.execute` — guard — only from the result screen: a fast in flight has nothing to undo, and zero staged elapsed means no ended fast on screen.
- `ResumeFastThunk.execute` — record removal — the record the ending wrote goes with it: as far as the user is concerned the fast never ended.
- `ResumeFastThunk.execute` — start timestamp — clock read here, not in the reducer (invariant 1); where it puts the start is `TimerState.startTimestamp(at:)`, shared with the start path.
- `ResumeFastThunk.execute` — `ProAction.autoOfferCancelled` — the ending that armed the offer is taken back, so its show goes too; the flag stays whole. The main guard between a mis-tapped End fast and a spent lifetime offer: a stray ending at 60% of the goal clears the quality threshold.
- `ResumeFastThunk.justRecorded(_:)` — identified by duration, not a remembered id: `HistoryMiddleware` builds the record with `end - start == elapsed`, the same `Double` `.stopped` staged, so they are equal, not close. The check makes the delete safe when there is no record: a fast under `HistoryMiddleware.minimumDuration` is never written, and deleting "the newest record" would throw away the previous fast.

## ScheduleNotificationsThunk.swift

- `ScheduleNotificationsThunk` — app-launch side effect that clears the legacy daily reminders. Authorization is asked on the first Start fast (`StartFastThunk`), where a push has a reason to exist; the goal-reached push is `NotificationMiddleware`'s.

## StartEatingThunk.swift

- `StartEatingThunk` — opens the window from the complete screen; length derives from the plan. The window is anchored to the meal (`fastEndTimestamp`), not the tap: someone who sat on the result screen an hour, or back-dated the ending by two, gets a window that closes on time instead of one that runs long and drags the chain. The tap stands in only when there is no confirmed ending (state persisted by a build that did not record one).

## StartFastThunk.swift

- `StartFastThunk` — dispatches `.started`, then asks for notification permission, the first moment a push has a reason to exist. One thunk because the ask must follow the start, and two thunks dispatched in a row are not ordered.
- `StartFastThunk.execute` — plan check (edge 9, second half) — a custom length no longer paid for cannot be started, but cannot be dropped silently either: someone who set seventeen hours would otherwise get sixteen with nothing said. The fast already running when the right went away was left alone; this is the next one.
- `StartFastThunk.execute` — `.started` goal — the plan as it stands *now* becomes the fast's goal and stops moving.
- `StartFastThunk.execute` — permission ask — `SyncPushStatusThunk.requestIfUndetermined`, shared with the Sunnah opt-in so both roads write `push_status` the same way.
