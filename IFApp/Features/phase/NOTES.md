# Phase - notes for agents

Why the phase code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## Phase.swift

- `Phase` — the "Verdant" metabolic phases. Phase and fraction are derived from elapsed time against the fast's goal: the four ring phases occupy quarters of the goal, and `autophagy` is the completed state past 100%.
- `Phase.color` — the Verdant spectrum: ring gradient, timeline bars, centre dot.
- `Phase.analyticsValue` — the GA4 value (`fast_stopped.stage`). Not `label`: the label is translated, so one phase would arrive as a different value per locale and the dimension could not be grouped. Stable English codes, written out rather than derived from `rawValue`, so reordering the cases cannot silently rewrite history.
- `Phase.exportValue` — the exported CSV's `phase` column (`HistoryExport`). Same rule as `analyticsValue` — fixed, unlocalised ASCII, never `label` — but a **different list**, and deliberately not shared with it. `analyticsValue` is a GA4 dimension registered against existing data: renaming `fed` to `satiety` there would split one phase across two values in every report ever run. The CSV list is the one product specified, naming the metabolic state rather than the ring colour. Two of the five agree by accident; that is no reason to fold them, because a change on either side must not travel to the other. Wrong values here are worse than in telemetry: a file that has left the phone cannot be corrected.
- `Phase.ringPhases` — the four phases drawn on the ring; `autophagy` is the completed state, not a quarter.

## PhaseProgress.swift

- `PhaseProgress.nextPhase` — nil once `autophagy` is reached.
- `PhaseProgress.secondsToNext` — 0 when complete.
