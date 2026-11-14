# DesignSystem - notes for agents

Why the tokens, type and shared controls are the way they are. Values come from the design handoff; read the section of a file before editing it, and an edit that changes or cancels a point below updates the point in the same commit.

## Color+Hex.swift

- `Color.init(hex:)` — `#RRGGBB` or `#RRGGBBAA`, with or without the leading `#`; used by the design tokens and the phase-derived colours.
- `Color.whiteAlpha(_:)` — the handoff's `rgba(255,255,255,a)` tokens.
- `Color.mix(_:_:)` — linear RGB interpolation toward `other` by `t` (0...1); matches the handoff's `mix(a,b,t)`, which the phase-reactive background and the next-phase chip are specified in.

## LabeledActionRow.swift

- `LabeledActionRow` — shared label and caption geometry for actions in the plan editor and the history. The caller owns its button, background, state and trailing affordance.

## PressableButtonStyle.swift

- `PressableButtonStyle` — the iOS replacement for the handoff's HTML hover affordance: depress on press only, ~0.97 scale plus a slight dim, 0.13s ease-out.

## ThemeTokens.swift

- `ThemeTokens` — design tokens for the two themes, Light "Mist" and Dark "Immersive", transcribed from the handoff. Resolved from the environment colour scheme: `ThemeTokens.resolve(colorScheme)`. `accent` / `deep` / `primaryButtonBg` are the single brand green, same role in both themes.
- `ThemeTokens.surfaceQuiet` — the quiet fill: the material the handoff gives to "this has weight, and it is not an action". A rank of its own rather than a reuse of `secBg` or `iconCircle`: those are white-on-white and a green wash, and neither carries `ink` at the contrast this rank owes. The Pro control in the header uses it, and the reversible-action surfaces of the consequence sheets are meant to be drawn on it too, which is why it is a token and not a colour spelled out inside one view.
- `ThemeTokens.surfaceQuietLine` — the hairline that keeps a control on `surfaceQuiet` from dissolving into the sheet behind it. Its own value rather than `surfaceLine`: the quiet fill sits almost on top of the sheet colour, so the edge it needs is lighter than the one a card draws against the app background, and reusing the card's would redraw a button as a panel.
- `ThemeTokens.buttonShadow` — the primary button's drop shadow: the button background at 0.32 (light) / 0.45 (dark).
- `ThemeTokens.phaseBackground(_:)` — the screen background tinted by the current phase colour, per the handoff: light PALE = `mix(phase, white, 0.86)`, dark DGLOW = `mix(phase, base, 0.80)`.
- `ThemeTokens.eatingWindowBackground` — the open eating window is a pause between fasts, not a stage of one: the phase timeline is deliberately absent from this state, so a phase-derived tint would contradict it; neutral green instead. Its own value rather than a reuse of `historyBackground` — two different things that land on the same green.
- `ThemeTokens.historyBackground` — the timer's phase-tint treatment in neutral green: history has no active phase to react to.
- `ThemeTokens.historyPhaseLabel(_:)` — the phase name under a record's plan pill: the phase colour pulled toward the text colour so it reads as a label, not as a second accent.
- `ThemeTokens.scaleTickMajor` — hour and day ticks on the last-meal ribbon, the ones the eye counts by; `scaleTickMinor` are the ordinary snap-step ticks.
- `ThemeTokens.scaleTickDayBreak` — the midnight rule: the only calendar mark on an otherwise relative scale.
- `ThemeTokens.chipSelectedBorder` — fill, border weight and text colour change together so the selection survives colour blindness.
- `ThemeTokens.chip(for:)` — the next-phase chip colours (dot / text / background / border), derived from the named phase colour.

## Typography.swift

- `Typography.timerNumerals` — timer numerals must be tabular: apply `.monospacedDigit()` at the call site.
- `Typography.timerSeconds` — the dimmed `:SS` suffix beside the elapsed H:MM.
- `Typography.statOverline` — uppercase, with tracking .13em applied at the call site (`overlineTracking`).

## Font+Typography.swift

- `Font.bricolage(_:_:)` — Bricolage Grotesque, the display family: timer numerals, titles, big headings (handoff weight 600). Both bundled families are variable fonts loaded by family name, with the weight selected through `.weight()`.
- `Font.hanken(_:_:)` — Hanken Grotesk, everything else: body, labels, buttons, stats (weights 400/500/600/700).

## View+Tracking.swift

- `OverlineTracking` — letter-spacing for the uppercase overline labels, suppressed in right-to-left (Arabic) layouts, where positive tracking breaks the connected cursive script and words read as disjointed letters, and in Korean, where 1.92pt at 12pt is 0.16em against a word space of 0.263em — enough of the gap that the eye reads syllable blocks as separate words.
- `DisplayTracking` — negative letter-spacing on display type, suppressed in Arabic, where tightening pulls a connected script apart, and in Korean, where it closes the gap between a syllable's 받침 and the stem of the next one until the two read as one block.
- `View.displayTracking(_:_:)` — `em`-relative tracking for display type, e.g. `displayTracking(25, -0.015)`.
