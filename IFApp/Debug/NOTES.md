# Debug - notes for agents

Why the diagnostics tooling is the way it is. Everything in this folder is compiled out outside DEBUG and DEVELOPMENT: nothing here reaches an App Store build. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## DebugOverlay.swift

- `DebugOverlay` — the two ways into the debug screen and the single place that owns its sheet: a draggable button for everyday use, a shake for when the button is not there.
- `DebugOverlay.isUITestLaunch` — the button hides itself on any UI-test launch. Every Maestro flow and every locale-matrix screenshot launches with a `-seed…` / `-uitest…` / `-show…` argument, so the check is exact rather than a guess; without it a floating circle would sit in every screenshot of the locale matrix and over whatever the visual-diff mode compares.
- `DebugOverlay.margin` — keeps the button off the very edge, where a drag would compete with the system's edge gestures.
- `DebugOverlay.drag(in:)` — `minimumDistance: 1` so a plain tap still reaches `onTapGesture`.
- `DebugOverlay.resolved(in:)` — live drag first, then the remembered spot, then a default clear of the primary button at the bottom of the timer screen.
- `DebugOverlay.clamped(_:in:)` — clamped on every read, not just on drop: rotating the device or switching to a smaller one would otherwise strand the button off-screen with no way back.

## DebugScreen.swift

- `DebugScreen` — the device end of diagnostics. On the simulator the journal is read straight off disk and this screen is unnecessary; on a real device there is no container to reach into, and Copy / Share are the only ways anything gets out. Not localised and not designed, on purpose: it has no reference screen, is never seen by a user, and every string is meant for whoever is debugging.
- `DebugScreen.tailLines` — enough to see how a flow ended without loading a multi-megabyte file into a view; the whole journal still goes out through Share.

## DiagnosticsSnapshot.swift

- `DiagnosticsSnapshot` — what the app believes about itself right now: build, App Store environment, storefront, and what the store says the product costs. The journal answers "what happened", this answers "where", and the two come up together: a price that looks wrong is not a bug until it is known which storefront produced it, and StoreKit's own view of the storefront is the only thing that separates a real mismatch from a TestFlight artefact.
- `DiagnosticsSnapshot` — reads StoreKit directly rather than through the store: these are facts about the environment, not app state, and diagnostic-only actions through the reducer would grow the product state machine to serve a debug screen.
- `DiagnosticsSnapshot.collect()` — the storefront is the point of the screen; `countryCode` is ISO-3 (UKR, USA, ITA). The device region sits beside it deliberately: the two disagreeing is itself the answer to most "wrong price" questions.
- `DiagnosticsSnapshot.environment()` — `.xcode` means a local StoreKit configuration is in play and every price on the screen is fiction; `.sandbox` covers both TestFlight and App Review.
- `DiagnosticsSnapshot.text(_:)` — the plain-text form, for the clipboard and the share sheet.

## FontMetricsDump.swift

- `FontMetricsDump` — measurement hook: prints the real `UIFontMetrics` scaling curve of the running OS to stdout and to `Documents/font-metrics.txt`. A no-op unless launched with `-dumpFontMetrics`. Layout questions ("does this string still fit at xxLarge?") are answered by a number only UIKit knows, and it is not a formula: the curve is a table, not linear, and changes between OS releases. Extrapolating it from two known points is wrong by up to 2.17pt at 20pt — enough to call a string safe that in fact clips — and the answer is needed for the whole string catalog, not one screen, so measuring is a tool rather than a one-off.
- `FontMetricsDump.runIfNeeded()` — usage on a simulator, no taps, no UI: `xcrun simctl launch --console-pty <UDID> simple-L.if-app.com -dumpFontMetrics`, or afterwards `cat "$(xcrun simctl get_app_container <UDID> simple-L.if-app.com data)/Documents/font-metrics.txt"`. Optional arguments, each taking the next argv item: `-dumpFontMetricsSizes 11,12,16,20` (base point sizes, default 10…24 by 1) and `-dumpFontMetricsStyle caption1` (text style, default body).
- `FontMetricsDump.runIfNeeded()` — the curve is asked of an injected `UITraitCollection`, not of the device's live setting, so every category is reported from one launch and the simulator's text-size slider need not be touched (or trusted).
- `FontMetricsDump.runIfNeeded()` — sizes — an unparsable or empty list falls back to the default range rather than dumping nothing: a typo must not look like "no data".
- `FontMetricsDump.runIfNeeded()` — `report(text)` — printed as well as written: on a build where the container is not reachable the table is still in the launch console, and a failed write says so instead of leaving an empty result that looks like a measurement.
- `FontMetricsDump.categories` — `.unspecified` is left out: it has no scale of its own and `scaledValue` resolves it to whatever is current, exactly the ambiguity this hook removes.
- `FontMetricsDump.report(_:)` — `print`, not `os.Logger`: the table is meant to be read verbatim from `simctl launch --console-pty`, and the logger's redaction and per-line prefix would break it into pieces.

## ShakeToOpen.swift

- `UIWindow.motionEnded(_:with:)` — SwiftUI has no shake gesture, and UIKit delivers motion events only down the responder chain, so the window reports the shake (`deviceDidShake`) and whoever cares listens. A first-responder-based catcher would have to compete with any focused control for that role; the window never does.
- `Notification.Name.deviceDidShake` — the shake is the fallback entry point, kept because it always works: the floating button can be switched off or hidden on a UI-test launch, and then this is the only way in.
