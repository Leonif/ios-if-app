# Plan - notes for agents

Why the plan code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## Plan.swift

- `Plan` — a plan is its fast length in whole hours; the four presets are the values that ship unlocked, not a closed set. Not an enum: a Pro custom goal makes any length in `range` possible, a position in a list cannot express "17 hours", and every label derived from a position would have to be written out case by case.
- `Plan` — states durations and nothing else. There is no wall-clock window ("12:00 - 8:00 PM"): the app runs on anchors, so the only true value is how long, and the live goal time is computed from the fast's start plus `fastHours`.
- `Plan.range` — 24 is deliberately outside it: at a 24h goal the eating window degenerates to zero and the fast → window → fast chain the app is built on stops existing. Anyone who wants a full day sets 23 and keeps going — reaching the goal does not stop the timer (the overtime state).
- `Plan.init(goalHours:)` — exact, because goals are whole hours everywhere they are produced (the presets and a picker of whole hours).
- `Plan.windowHours` — never zero; that is what `range` buys. The single definition of "the eating window is what the fast leaves of the day": the ratio label, the window in the editor and the moment the window closes all come from here. Two copies drifting would be silent — "17:7" over a window that runs six hours looks normal on both screens.
- `Plan.ratioLabel` — computed, so a custom 17h plan reads "17:7" the same way a preset does. Not localised on purpose: a pair of numerals, and Western digits are pinned app-wide.
- `Plan.isPreset` — one of the four lengths free for everyone.
- `Plan.allowed(isPro:)` — the single definition of the gate, on the plan rather than on `AppState`, because the two questions asked are about two different plans: the editor asks about the length on the wheel, which is deliberately not in the store until it passes here, and `AppState.selectedPlanAllowed` asks about the length in the store (the next start reads it through that projection). A rule hosted on state could only answer the second.
- `Plan.analyticsLabel` — the GA4 value (`plan_selected` / `plan_confirmed` / `current_plan`). Presets keep their ratio so the existing breakdown survives; custom goals collapse into `custom:17` rather than spraying the dimension with one label per hour.
- `Plan.nearestPreset` — the free plan this one falls back to when the entitlement goes away: nearest by length, downwards on a tie — a goal the user cannot reach is worse than one they overshoot. A preset returns itself.
- `Plan.presets` — in the order the segmented control shows them.

## PlanState.swift

- `PlanState.plan` — stored as the value itself, not a position in a list: a custom goal has no position.

## PlanAction.swift

- `PlanAction.selected(hours:)` — a preset tap and a custom goal are the same event; they differ only in the value.

## PlanReducer.swift

- `planReducer(state:action:)` — out-of-range values are dropped, not clamped: they can only come from a wrong caller, and silently selecting a neighbouring plan would hide that. Entitlement is not checked here: whether a custom length may be confirmed is decided at the point of confirmation, which is where the offer opens instead.
