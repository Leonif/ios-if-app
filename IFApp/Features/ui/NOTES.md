# UI - notes for agents

Why the presentation-state code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## UIState.swift

- `UIState` — presentation flags kept in the store so sheet state is part of the single source of truth, matching the handoff prototype's `editing` / `mealOpen`.
- `UIState.endEatingConfirmOpen` — a confirmation in front of ending an open eating window early: a footer button that ends it on the tap reads as "close this screen".

## SyncPushStatusThunk.swift

- `SyncPushStatusThunk` — records whether notifications are enabled as the `push_status` user property. The goal and eating-window pushes and the Sunnah reminders reach only users who allowed notifications, so any funnel that counts on a push bringing the user back (the goal push returning them to end the fast) is unreadable without knowing who could receive it. Dispatched once per cold launch from `IFAppApp.init`: nothing is asked at launch, so it only reports the current state and picks up permission changes made in iOS Settings between sessions.
- `SyncPushStatusThunk.requestIfUndetermined(notifications:analytics:dispatch:)` — the one place a permission ask happens, shared by `StartFastThunk` and `SunnahMiddleware` so both entry points leave `push_status` in the same state; a separate copy on one path leaves the property at `notDetermined` until the next cold start. Asks only while `notDetermined`: the system prompt is one-time, and on `denied` a repeat call shows nothing. `push_status` is written from the status read back *after* the answer, so it reflects what the user chose (possibly partial), not what was asked; then `pushAuthorizationResolved` lets goal/eating pushes refused before the grant reschedule. Returns whether the dialog was shown.
- `SyncPushStatusThunk.promptSuppressed` — the `-suppressPushPrompt` launch argument: UI tests drive Start fast, and the system dialog would cover the screen and break the flow. DEBUG-only, like `UITestSeed`.
- `SyncPushStatusThunk.label(for:)` — the `push_status` values: a fixed list, the analytics contract.
