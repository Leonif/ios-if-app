# IFAppUITests - notes for agents

Why the XCUITest click-through is set up the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## IFAppUITests.swift

- `IFAppUITests` — a click-through of the fasting flow that attaches a screenshot (`attach(_:_:)`, kept always) at each state, so the same run doubles as a localized-layout check: run it per locale with `xcodebuild test -scheme IFAppUITests -testLanguage de -testRegion DE ...` and look at the attachments.
- `IFAppUITests.testFastingClickThrough` — launches with `-suppressPushPrompt` besides `-uitestReset`: Start fast asks for notification permission on a fresh install, and the system dialog would cover the screen and break the drive-through.
- `IFAppUITests.testEatingOverContinue` — `-seedEatingElapsed 28920` is a 16:8 plan's 8h window plus two minutes: the window has just closed, so the launch lands on the window-closed screen rather than an open window.
- `IFAppUITests.testEatingOverTimeout` — the seed is the 8h window plus 25h past the close: a window that closed 24h or more ago times out to plain idle, not the chain screen, and 25h clears that boundary with margin.
- `IFAppUITests.testHistoryNoEntryWithoutRecords` — with no records there is nowhere to go, so the header carries no pill at all; the entry point arrives with the first finished fast.
- `IFAppUITests.testHistoryEntryWithoutStreak` — records but a broken streak: the pill stays, reading "History" instead of a zero, and still opens the screen.
- `IFAppUITests.testHistoryEdgeCases` — `-seedHistoryEdge` seeds the data shapes the layout has to survive: across midnight, past 40 hours, short of the goal, and two in one day.
