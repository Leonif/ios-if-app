# End fast - notes for agents

Why the end-of-fast correction sheet's code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

State names S1-S4 are the sheet's four cards from its handoff: S1 the ordinary picker, S2 near goal, S3 overtime, S4 refusal.

## EndFastState.swift

- `EndFastState` — the sheet's single source of truth. A mirror of the last-meal picker asking about the other end of the fast: not "when did it start" but "when did it end", which without the sheet is the moment of the tap with no way to say otherwise.
- `EndFastState.nearGoalThresholdMinutes` — exactly 15 whole minutes: at 15:00 left the state is on, at 15:01 it is off.
- `EndFastState.overtimeNeutralThreshold` — how far past the goal a fast runs before the app stops encouraging and offers the correction instead. One constant, read by both surfaces of one fast: this sheet's S3 (`OpenEndFastThunk`) and the main screen's editorial copy (`TimerFlowView.editorial(state:progress:elapsed:)`). If only one reads it, the main screen goes on praising "deeper autophagy" at hour 41 while the sheet behind the same button offers to correct the fast.
- `EndFastState.minimumFastDuration` — the nearest a chosen end may come to the start; under a minute apart the two are the same moment and the record is not a fast.
- `EndFastState.fastStartTimestamp` — carried so the preview can name the duration a choice implies without the view reaching into another substate.
- `EndFastState.earliest` — the reachable range (`earliest`...`latest`), injected at open and refreshed by every control that reads the clock. Nothing outside it is expressible: neither the future nor a moment before the fast began.
- `EndFastState.conflict` — non-nil is the whole of the refusal state (S4); there is no separate flag to disagree with it.
- `EndFastState.conflictUnavoidable` — the collision is on the fast's own start, so no end can clear it: the refusal drops "pick another time" (which would only loop) and leaves removing the old record as the one way out.
- `EndFastState.showsStepper` — the exact-time control and its divider leave S2 and only S2: whoever pressed End fast that close to the goal is confirming a moment, not authoring one, and the freed height pays for the second action inside the sheet's height budget. S3 is where precision is the point, so it keeps them.

## EndFastEntry.swift

- `EndFastEntry` — how the sheet was entered, which decides the picker state drawn. Captured once by `OpenEndFastThunk`, not recomputed from the clock while the sheet is up: the card must not change shape under the user's finger — a fast 15:00 short of its goal stays `nearGoal` while the minute rolls over. It also keeps the clock out of the reducer (invariant 1): every branch is decided from an injected payload.
- `EndFastEntry.ordinary` — S1: the goal is still far off, or passed recently enough that there is nothing extra to say.
- `EndFastEntry.nearGoal` — S2: whole minutes left to the goal, 1...15.
- `EndFastEntry.overtime` — S3: entered past the neutral-copy threshold — the person forgot to stop and came to correct rather than to confirm.

## EndFastStage.swift

- `EndFastStage` — which of the four mutually exclusive cards is on screen. Derived, never stored: two facts decide it (how the sheet was entered, and whether the current choice collides with a saved fast), and a third copy of that decision is how a header ends up over a body it no longer describes.

## EndFastAction.swift

- `EndFastAction` — clock-dependent values are injected by thunks; the reducer stays pure. Every action that moves the choice also carries `latest`, because "now" is the right edge of the reachable range and it moves while the sheet is open.
- `EndFastAction.opened` — everything the four states branch on arrives at once, resolved against a single reading of the clock.
- `EndFastAction.refused(conflict:unavoidable:)` — carries the record itself so the reason can name it: a refusal that does not say what is in the way is the silent "no" this state exists to replace.
- `EndFastAction.refusalWithdrawn` — "Pick another time": back to the picker with the previous choice intact.
- `EndFastAction.closed` — the sheet closed without ending the fast: the scrim, or `Keep this fast`.

## EndFastReducer.swift

- `endFastReducer(state:action:)` — `.refusalWithdrawn` keeps the choice on purpose: the person is sent back to change one thing, and a reset picker would make them re-enter the part that was fine.
- `clamp(_:_:_:)` — clamped rather than rejected: a control that refuses to move is the silent "no" the refusal state exists to replace. The bounds are the fast's start plus a minute and the present moment, so a value outside them is not a choice the sheet can express at all.

## EndFastMath.swift

- `EndFastMath` — pure; "now" is injected, so none of it reads the clock from a view.
- `EndFastMath.quickOffsetsMinutes` — `Just now` is an offset of zero rather than a special case, so the presets are one list and no chip can lack a moment behind it.
- `EndFastMath.chips(stage:now:selected:)` — the shape is the state's business: minutes-ago while the ending is recent, whole past days once the timer ran a day or more past the goal ("30 min ago" offers nothing to someone correcting a fast forgotten for two days). The overtime presets keep the clock time of the standing choice (which starts on the goal end) on each of the three days before today: the one hour the app can justify, without inventing a dinner time it cannot know.
- `EndFastMath.resolve(_:now:selected:)` — the one definition of the instant a chip stands for: the row calls it to build labels, the thunk to set the value, so a chip cannot say one moment and select another.
- `EndFastMath.shiftedByDays(_:days:relativeTo:)` — calendar arithmetic, not ±86400: an hour disappears twice a year, and a preset an hour off on those days is worse than none.
- `EndFastMath.dayAndClock(_:now:)` — the clock is isolated where it enters the string, for the reason in `Features/meal/NOTES.md` (`MealMath.fromLabel`): mid-line it is a token like any other substitution.
- `EndFastMath.dayCaption(_:now:isGoalEnd:)` — which day the value is on, and, when the sheet opened on it, that this is where the goal ran out.
- `EndFastMath.isNearGoal(secondsLeft:)` — whole minutes rounded up: 15:00 left is 15 and inside the guard, 15:01 is 16 and outside; rounding down would put a fast 15:59 short inside a guard that says "15 minutes left". Its one reader is `OpenEndFastThunk`, deciding whether to warn before an irreversible tap. The result footer deliberately does not ask it: after the fast is written the only question is whether the day counted, and there fifteen minutes short and eight hours short are the same answer.
- `EndFastMath.clock(_:)` — the region's 12/24h convention with Latin digits, like every clock the app draws.
- `EndFastMath.recordSpan(_:now:)` — both ends of the conflicting fast, because one of them is what the person must move away from and they cannot tell which without the span. The span never breaks across lines: an ASCII hyphen with ordinary spaces gives the layout two break points inside one value ("(Yesterday 9:00 -" / "1:10)"), and the line that names the conflict reads as two unrelated times (found by the Korean and Japanese passes).
- `EndFastMath.spanSeparator` — non-breaking spaces around the hyphen everywhere; in Japanese the full-width wave dash (12:00〜21:45) with no spaces, since it carries its own side bearings.

## EndFastChipOffset.swift

- `EndFastChipOffset` — what a preset means, independent of when it is tapped. The row hands this back rather than an absolute moment: the sheet is drawn from a `TimelineView` that redraws every second, so a moment resolved at draw time is the moment of a *frame*, not of the tap. `EndFastMath.resolve` turns it into an instant once, inside the thunk.
- `EndFastChipOffset.daysBack` — whole days back from the standing choice, keeping its clock time: the overtime presets.

## EndFastChip.swift

- `EndFastChip` — offset and label travel together because the label is a statement *about* the offset; built separately they drift, and a chip says "1 h ago" and sets something else.

## OpenEndFastThunk.swift

- `OpenEndFastThunk` — "End fast" does not end the fast: it opens the correction sheet, and the fast keeps running until the sheet is confirmed. That makes a mis-tap reversible without an undo, and lets someone who forgot to stop say when they actually ate.
- `OpenEndFastThunk.execute(state:dispatch:)` — one reading of the clock, and everything the four states branch on is resolved from it. Read twice, the state the sheet opens in and the range it clamps to could disagree by a second — and the second that matters is the one either side of the near-goal threshold.
- `OpenEndFastThunk.execute(state:dispatch:)` — overtime default — past the threshold the default end stops being "just now": someone a day or more past their goal is here to correct, and the moment they most plausibly mean is the one the goal ran out on.

## EndFastChipThunk.swift

- `EndFastChipThunk` — the two controls that move the choice go through a thunk because the right edge of the range is "now" and moves while the sheet is open; a clamp against the bound captured at open would let the future through the moment the user paused to read. The chip's moment is resolved here, at the tap: the sheet redraws every second, so a moment resolved in the view is that of whichever frame the finger landed on.

## EndFastStepThunk.swift

- `EndFastStepThunk` — the exact-time control, ± one step, carrying a fresh `latest` for the same reason.

## ConfirmEndFastThunk.swift

- `ConfirmEndFastThunk` — the single point a fast ends; the moment comes from the sheet, and the tap only confirms it.
- `ConfirmEndFastThunk` — the overlap guard lives here rather than in `HistoryMiddleware` for the reason the refusal state exists at all: a write that quietly does not happen is the silent "no", and middleware has no way to say anything. The check runs where an answer can still be given.
- `ConfirmEndFastThunk.execute(state:dispatch:)` — the end is re-clamped against the clock at the tap, not as it stood when the control last moved: a sheet left open crosses no boundary, but "now" has moved on, and only this side of it may be written.
- `ConfirmEndFastThunk.execute(state:dispatch:)` — unavoidable — if even the shortest allowed fast (ending the instant it is old enough) still overlaps, the clash is on the start and no end could clear it; the refusal is told so it can drop "pick another time".
- `ConfirmEndFastThunk.execute(state:dispatch:)` — `qualifies` is analytics-only (`fast_stopped.completed`) and gates nothing. Computed from the confirmed end, not the tap, so a fast abandoned before its goal does not read as taken.
- `ConfirmEndFastThunk.execute(state:dispatch:)` — the one-time offer (T1' in `Features/pro/NOTES.md`) is armed here: the fast that just ended is the only thing that can arm it, and this is the last point where its elapsed time and the goal it ran to are both at hand. Arming is not showing: the moment comes once the user has left the complete state through the eating window, and anything in between (a rollback, a Reset, a review prompt, the session ending) cancels or suppresses it without costing the show.
