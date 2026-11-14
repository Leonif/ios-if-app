# Sunnah - notes for agents

Why the Sunnah reminders code is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## SunnahSettingsView.swift

- `SunnahSettingsView` — one state is not a variant of the others: with notifications refused in iOS Settings nothing here can ever be delivered. A green switch on top, upcoming dates below and the refusal as a grey line between them would say the opposite. So `denied` reorders the screen rather than annotating it: the refusal and the way out come first, the switches stop reading as a running schedule, and the upcoming list is gone (`SunnahMiddleware` sends no dates it did not schedule).
- `SunnahSettingsView.isDenied` — `denied` is the one delivery state the layout itself answers to.
- `SunnahSettingsView.body` — switches — stay operable while denied (they are how someone turns the opt-in back off) but lose the on-tint, the part that claims a schedule exists.
- `SunnahSettingsView.body` — reminder time — one system `DatePicker` for one fact: two wheels (hour and minute apart) make the user assemble a time the system already knows how to ask for, ignoring their 12h/24h convention and digits, and cost two strings of their own. Disabled while both switches are off: with nothing scheduled there is no reminder for a time to belong to.
- `SunnahSettingsView.body` — picker locale — `.environment(\.locale, .latinDigits)`, because the control formats its own digits. The language is untouched, so the clock convention stays the locale's (24h in de, 12h in en); without it Arabic reads "٨:٠٠ م" above an upcoming-dates list pinned to Latin — the two numbering systems on one screen that `Locale.latinDigits` exists to prevent.
- `SunnahSettingsView.body` — upcoming list — never a list of dates under a refusal, whatever the state still holds from before the permission changed.
- `SunnahSettingsView.statusText` — `.denied` does not reach this text (the refusal owns its own section above, and this row is hidden while it does); the case stays because the switch is exhaustive over the states, not over the ones this row renders.
- `SunnahSettingsView.reminderTime` — the stored minute of a civil day as the clock value the system picker takes. The date carried is today's and only the time components are read back, so the value never becomes a calendar moment. `bySettingHour` first because it survives a clock change: on a spring-forward day, adding 20 hours to midnight lands at 21:00. The fallback adds them anyway rather than returning the current time — a control that cannot resolve the stored setting must not answer with "now", a different value stated as if it were the saved one.

## SunnahState.swift

- `SunnahState.Delivery.resolve(enabled:otherwise:)` — disabled reminders are `.off` and nothing else, whether the schedule has run or not: one definition for the reducer's provisional value and the middleware's settled one.

## SunnahReducer.swift

- `sunnahReducer` — `.refresh` changes nothing here: it asks `SunnahMiddleware` to read the permission and reschedule, and the answer arrives as `deliveryUpdated`. Until it does, `settingsChanged` leaves the provisional delivery from `SunnahState.Delivery.resolve(enabled:otherwise:)` — `.checking`, or `.off` when disabled.

## SunnahSettings.swift

- `SunnahSettings.analyticsMode` — the GA4 `mode` dimension: a fixed ASCII list, never a displayed label — the switches are localised in ten languages and a dimension carrying their text could not be grouped.
- `SunnahSettings.clamped(minuteOfDay:)` — the domain clamp, and the only one: a reminder time is a minute of a civil day. Both roads a value enters by — the picker (via the reducer) and the stored blob (via the repository) — pass through here.

## SunnahSchedule.swift

- `SunnahSchedule` — civil-date reminders, not a sunrise/sunset calculation; all time inputs are explicit.
- `SunnahSchedule.maxReminders` — how many reminders are ever scheduled at once; `SunnahRepository` sizes its share of the pending-notification budget from it.
- `SunnahSchedule.reminders(settings:now:timeZone:limit:)` — Ramadan is skipped (it is not a voluntary weekly schedule), and Eid and the days of Tashriq are never suggested.
