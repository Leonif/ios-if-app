# Launch - notes for agents

Why the launch splash is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## LaunchSplash.swift

- `LaunchSplash` — a pure UI layer over the first screen: it owns no store and dispatches nothing, so Redux bootstrap in `IFAppApp.init()` runs in parallel with it and never waits for it. It ends itself through the completion of its one linear `withAnimation`; no timer, `Task` or `asyncAfter` is involved (invariant 2).
- `LaunchSplash` — the geometry and timing are a port of the owner-approved reference render (`sun-rd`, mode "draw" of the generator), in the LaunchMark's own units: ring band 115.8...145.2, head radius 28.2 on an orbit of 127, outer radius = 150/720 of the screen width. Change them only against a new reference.
- `LaunchSplash` — `.environment(\.layoutDirection, .leftToRight)` — the head and the band are placed by angle (invariant 13).
- `SplashTiming.drawn` — 2.0 s draw with `0.5 - 0.5·cos(πt)` easing, 0.4 s hold on the finished logo, 0.4 s hand-off. The head starts at 12 o'clock and travels 360° plus the angle to the LaunchMark dot (`atan2(61.67 - 148, 241.17 - 148)`), so the last frame of the draw is the logo itself.
- `SplashTiming.drawn` — the head fade-in (`drawProgress / 0.08`) and the dusk-to-day background (`drawProgress * 1.15`) are fractions of the 2.0 s draw, as in the reference: 0.16 s and ~1.74 s in wall time.
- `SplashTiming.still` — Reduce Motion: no travel and no move into the timer ring; the finished logo fades in with the morning background, holds, and fades out.
- `SplashPalette.launch` — the launch screen (`UILaunchScreen.UIColorName` = `LaunchDusk`) can only be a solid colour, while the splash opens on a vertical dusk gradient. `LaunchDusk` is the mean of the gradient's two ends, and the splash paints it on top at full opacity in its first frame and fades it out over `launchDuskFade` (0.25 s), so the hand-over from the system launch screen has no seam. Keep the colorset equal to the mean of `duskTop` / `duskBottom` for both appearances.
- `SplashPalette.day` — reuses `LaunchBackground`, the colour the app background settles on; that colorset is used elsewhere and stays as it is.
- `SplashPalette.ring` — 36 colour stops sampled every 10° from `LaunchMark@3x.png` on the band's mid radius (130.5 pt), starting at 9 o'clock to match `conicGradient(angle: 180°)`; the stops under the logo dot are interpolated across the cut. The colour is tied to the angle, not to the drawn length, so the band reveals a fixed gradient. `dot` is the LaunchMark dot sampled at its centre.
- `SplashFrame.draw(in:size:)` — the cutout of radius `dotRadius * 1.42` around the head is clipped out of the band, never painted over it, so in both themes it shows whatever background is under it and the head never overlaps the line. The band ends at the head's angle and never wraps over itself: after a full turn it becomes the closed annulus.
- `SplashFrame.draw(in:size:)` — hand-off — when `TimerFlowView.RingAnchorKey` delivers the timer ring's frame, the logo scales so its mid radius matches the ring's centre-line radius and slides onto it, fading as `1 - p²` so it lands before it dissolves; the background fades linearly, so the screen shows through. On screens without the ring (eating window) the logo fades in place.
