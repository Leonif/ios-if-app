//
//  TimerFlowView.swift
//  IFApp
//
//  The redesigned fasting screen on Redux. Reads a Props projection, derives the
//  Verdant phase/fraction from elapsed vs the plan goal, and composes the ring,
//  editorial, timeline, footer, and the plan/meal sheets. Elapsed is derived from
//  fastStart + a TimelineView tick.
//

import SwiftUI
import UIKit
import Redux

struct TimerScreenProps: Equatable {
    let isRunning: Bool
    let fastStartTimestamp: Double
    let stagedElapsed: TimeInterval
    let hasCelebrated: Bool
    let isEating: Bool
    let eatingStartTimestamp: Double
    let planIdx: Int
    let ateDay: Int
    let ateMin: Int
    let planEditorOpen: Bool
    let mealPickerOpen: Bool
    let reviewPromptOpen: Bool
    let resetConfirmOpen: Bool

    init(state: AppState) {
        isRunning = state.timerState.isRunning
        fastStartTimestamp = state.timerState.fastStartTimestamp
        stagedElapsed = state.timerState.stagedElapsed
        hasCelebrated = state.timerState.hasCelebrated
        isEating = state.timerState.isEating
        eatingStartTimestamp = state.timerState.eatingStartTimestamp
        planIdx = state.planState.planIdx
        ateDay = state.mealState.ateDay
        ateMin = state.mealState.ateMin
        planEditorOpen = state.uiState.planEditorOpen
        mealPickerOpen = state.uiState.mealPickerOpen
        reviewPromptOpen = state.uiState.reviewPromptOpen
        resetConfirmOpen = state.uiState.resetConfirmOpen
    }

    var plan: Plan { Plan(rawValue: planIdx) ?? .default }
    var isMealFresh: Bool { ateMin < 0 }

    /// Eating-window length in hours: the remainder of the 24h day after the fast.
    var eatingHours: Double { 24 - plan.fastHours }

    func elapsed(at now: Date) -> TimeInterval {
        isRunning ? max(0, now.timeIntervalSince1970 - fastStartTimestamp) : stagedElapsed
    }

    /// Seconds left in the eating window (until the next fast should start).
    func eatingRemaining(at now: Date) -> TimeInterval {
        max(0, eatingStartTimestamp + eatingHours * 3600 - now.timeIntervalSince1970)
    }
}

private enum ScreenState { case idle, active, goalReached, complete, eating }

struct TimerFlowView: View {
    private let store: Store<AppState>
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var props: TimerScreenProps
    @State private var showSources = false

    // Goal-reached moment / overtime glow — driven here so the one-shot plays only
    // on a genuine live crossing and is not replayed when relaunching mid-overtime.
    @State private var goalSealScale: CGFloat = 0
    @State private var goalHaloOpacity: Double = 0
    @State private var goalSweepAngle: Double = 0
    @State private var goalSweepOpacity: Double = 0

    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: TimerScreenProps(state: store.getCurrentState()))
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        Group {
            // Tick every second while a fast runs or an eating window counts down.
            if props.isRunning || props.isEating {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    screen(theme: theme, now: ctx.date)
                }
            } else {
                screen(theme: theme, now: Date())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundLayer(theme: theme))
        .overlay {
            // The sheets ship transitions, but props land from the store as a plain
            // assignment — without an animation bound to the flag the transition
            // never runs and the sheet just pops in. Scoped to this one flag so the
            // per-second timer ticks stay unanimated.
            overlays(theme: theme)
                .animation(.easeOut(duration: 0.3), value: props.reviewPromptOpen)
                .animation(.easeOut(duration: 0.3), value: props.resetConfirmOpen)
        }
        .sheet(isPresented: $showSources) { SourcesView() }
        .connect(to: store, mapState: { TimerScreenProps(state: $0) }, onPropsChange: { props = $0 })
        .onAppear {
            store.dispatch(AppLifecycleAction.themeActive(dark: colorScheme == .dark))
            // Restore the settled overtime end-state on a relaunch mid-overtime
            // (onChange below won't fire for the initial state).
            syncGoalMoment(to: currentScreenState())
            // An eating window may have elapsed while the app was closed.
            reconcileEating(currentScreenState())
        }
        .onChange(of: colorScheme) { _, new in
            store.dispatch(AppLifecycleAction.themeActive(dark: new == .dark))
        }
        .onChange(of: scenePhase) { _, phase in
            // The goal can be crossed while we're backgrounded; the moment waits
            // here until the user is actually looking at the screen.
            guard phase == .active else { return }
            syncGoalMoment(to: currentScreenState())
            reconcileEating(currentScreenState())
        }
    }

    // MARK: Background (phase-reactive)

    private func backgroundLayer(theme: ThemeTokens) -> some View {
        let progress = PhaseProgress.compute(elapsed: props.elapsed(at: Date()), goalHours: props.plan.fastHours)
        return theme.phaseBackground(progress.phase.color).ignoresSafeArea()
    }

    // MARK: Main screen

    @ViewBuilder
    private func screen(theme: ThemeTokens, now: Date) -> some View {
        let elapsed = props.elapsed(at: now)
        let progress = PhaseProgress.compute(elapsed: elapsed, goalHours: props.plan.fastHours)
        let state = screenState(progress: progress, now: now)
        let nowMinute = Clock.minuteOfDay(now)

        // Read the real safe-area insets so the top/bottom gaps adapt to the device.
        // The header is a transparent floating overlay above a full-height ScrollView:
        // it sits just below the status bar with no backdrop, so when the ring scrolls
        // up it slides *under* the floating plan pill / notes icon and stays visible
        // around them. The footer stays pinned above the home indicator. The middle
        // (ring/editorial/timeline) scrolls between them so a short screen (SE) can
        // reach the timeline while the full 280pt ring holds its resting spot.
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            // Header geometry. `headerTop` matches the old .padding(.top, 14); the
            // controls are ~34pt tall; `headerGap` is the old 24pt header->ring gap.
            // The scroll content reserves (top + height + gap) at the top so the ring
            // rests below the header exactly where it did before, yet can scroll under it.
            let headerTop: CGFloat = 14
            let headerHeight: CGFloat = 34
            let headerGap: CGFloat = 24

            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if state == .eating {
                        // Eating window: a calm countdown to the next fast — no ring, no phases.
                        VStack(spacing: 20) {
                            EatingWindowCard(remaining: props.eatingRemaining(at: now), theme: theme)
                                .padding(.vertical, 6)

                            EditorialSentence(text: PhaseCopy.complete, theme: theme)
                        }
                    } else {
                        VStack(spacing: 20) {
                            ZStack {
                                PhaseRing(progress: progress.fraction, currentPhase: progress.phase,
                                          isComplete: state == .complete || state == .goalReached, theme: theme,
                                          diameter: 280)
                                if state == .goalReached {
                                    GoalMomentView(sealScale: goalSealScale, haloOpacity: goalHaloOpacity,
                                                   sweepAngle: goalSweepAngle, sweepOpacity: goalSweepOpacity,
                                                   theme: theme, diameter: 280)
                                }
                                ringCenter(state: state, elapsed: elapsed, progress: progress, theme: theme)
                            }
                            .padding(.vertical, 6)

                            EditorialSentence(text: editorial(state: state, progress: progress), theme: theme)

                            if state == .active, let next = progress.nextPhase {
                                NextPhaseChip(next: next, secondsToNext: progress.secondsToNext, theme: theme)
                            }

                            if state == .goalReached {
                                StaticPhaseChip(phase: .autophagy, text: strings.Timer.deepAutophagy, theme: theme)
                            }

                            if state == .idle {
                                LastMealPill(
                                    valueText: mealValue(nowMinute: nowMinute),
                                    subline: mealSubline(nowMinute: nowMinute),
                                    theme: theme,
                                    onTap: { store.dispatch(OpenMealPickerThunk()) }
                                )
                            }

                            PhaseTimeline(currentPhase: progress.phase,
                                          currentFill: progress.fraction * 4 - Double(progress.phase.rawValue),
                                          isComplete: state == .complete || state == .goalReached,
                                          theme: theme)
                                .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                // Reserve room for the floating header so the ring rests below it, yet
                // scrolls up under the transparent plaques when the user drags.
                .padding(.top, headerTop + headerHeight + headerGap)
                // Breathing room so the timeline doesn't butt against the pinned
                // footer when the middle scrolls on a short screen.
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Transparent floating header: no backdrop, just the plan pill and notes
            // icon (each keeps its own iconCircle). It floats above the scroll so the
            // ring shows through/around it while scrolling.
            .overlay(alignment: .top) {
                TimerHeader(
                    plan: props.plan,
                    theme: theme,
                    onEditPlan: { store.dispatch(UIAction.planEditorOpened) },
                    onSettings: { showSources = true }
                )
                .padding(.top, headerTop)
                .padding(.horizontal, 24)
            }
            // Footer pinned above the scroll: it lifts off the bottom edge by the
            // home-indicator inset, or a fixed minimum on home-button devices (inset 0)
            // so it isn't jammed against the edge. The primary action stays visible; the
            // scroll content reserves room for it. The colored background fills under it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer(state: state, elapsed: elapsed, theme: theme)
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(insets.bottom, 32))
                    .frame(maxWidth: .infinity)
                    // Opaque backdrop so the translucent footer card doesn't let the
                    // scrolling middle (chip/timeline) show through on a short screen.
                    // The phase background is a radial gradient centered near the top; by
                    // the footer it has fully resolved to backgroundBase, so this matches
                    // seamlessly and fills into the bottom safe area to the screen edge.
                    .background(theme.backgroundBase)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        // Detect the goal crossing here (inside the per-second tick) — it is
        // time-driven, so the outer body wouldn't re-evaluate to catch it.
        .onChange(of: state) { _, newState in
            syncGoalMoment(to: newState)
            reconcileEating(newState)
        }
    }

    private func screenState(progress: PhaseProgress, now: Date) -> ScreenState {
        // An open eating window shows the countdown until it closes, then falls to idle.
        if props.isEating {
            return props.eatingRemaining(at: now) > 0 ? .eating : .idle
        }
        if !props.isRunning { return props.stagedElapsed > 0 ? .complete : .idle }
        // Running: past the goal is the overtime "goal reached" state, else active.
        return progress.isComplete ? .goalReached : .active
    }

    // MARK: Ring center

    @ViewBuilder
    private func ringCenter(state: ScreenState, elapsed: TimeInterval, progress: PhaseProgress, theme: ThemeTokens) -> some View {
        switch state {
        case .idle:
            RingCenterIdle(theme: theme, onStart: { store.dispatch(StartFastThunk()) })
        case .active:
            RingCenterActive(elapsed: elapsed, phase: progress.phase, theme: theme)
        case .goalReached:
            RingCenterGoalReached(elapsed: elapsed, goalSeconds: props.plan.fastHours * 3600, theme: theme)
        case .complete:
            RingCenterComplete(elapsed: elapsed, theme: theme)
        case .eating:
            // The eating window renders its own ring-free card (see screen()).
            EmptyView()
        }
    }

    // MARK: Footer

    @ViewBuilder
    private func footer(state: ScreenState, elapsed: TimeInterval, theme: ThemeTokens) -> some View {
        switch state {
        case .idle:
            EmptyView()
        case .active:
            ActiveFooterCard(
                startedAt: clockTime(props.fastStartTimestamp),
                elapsed: hoursMinutes(elapsed),
                goalLabel: strings.Duration.goalHours(Int(props.plan.fastHours)),
                goalAt: clockTime(props.fastStartTimestamp + props.plan.fastHours * 3600),
                theme: theme,
                onEndFast: { store.dispatch(StopFastThunk()) }
            )
        case .goalReached:
            GoalReachedFooterCard(
                fasted: hoursMinutes(elapsed),
                goal: hoursMinutes(props.plan.fastHours * 3600),
                over: "+" + overtimeShort(elapsed - props.plan.fastHours * 3600),
                theme: theme,
                onReset: { store.dispatch(UIAction.resetConfirmOpened) },
                onEndFast: { store.dispatch(StopFastThunk()) }
            )
        case .complete:
            CompleteFooterCard(
                fasted: hoursMinutes(elapsed),
                windowOpens: strings.Meal.now,
                theme: theme,
                onReset: { store.dispatch(ResetFastThunk()) },
                onStartEating: { store.dispatch(StartEatingThunk()) }
            )
        case .eating:
            EatingFooterCard(
                theme: theme,
                onSkip: { store.dispatch(TimerAction.eatingEnded) },
                onStartFast: { store.dispatch(StartFastThunk()) }
            )
        }
    }

    // MARK: Overlays (sheets)

    @ViewBuilder
    private func overlays(theme: ThemeTokens) -> some View {
        if props.planEditorOpen {
            PlanEditorSheet(
                plan: props.plan,
                theme: theme,
                onSelect: { store.dispatch(PlanAction.selected($0)) },
                onDone: { store.dispatch(UIAction.planEditorClosed) },
                onClose: { store.dispatch(UIAction.planEditorClosed) }
            )
            .zIndex(1)
        }
        if props.mealPickerOpen {
            let nowMinute = Clock.minuteOfDay()
            LastMealPickerSheet(
                dateLabel: MealMath.dateLabel(ateDay: props.ateDay),
                timeLabel: MealMath.timeLabel(ateMin: props.ateMin),
                previewText: mealPreview(nowMinute: nowMinute),
                theme: theme,
                onQuickChip: { store.dispatch(QuickMealChipThunk(minutesAgo: $0)) },
                onDayStep: { store.dispatch(MealAction.dayStepped(by: $0)) },
                onTimeStep: { store.dispatch(MealAction.timeStepped(by: $0)) },
                onConfirm: { store.dispatch(ConfirmLastMealThunk()) },
                onClose: { store.dispatch(UIAction.mealPickerClosed) }
            )
            .zIndex(1)
        }
        ReviewPromptSheet(
            isOpen: props.reviewPromptOpen,
            theme: theme,
            onPositive: { store.dispatch(LeaveReviewThunk()) },
            onDismiss: {
                store.dispatch(UIAction.reviewPromptClosed)
                store.dispatch(AppLifecycleAction.reviewPromptDismissed)
            }
        )
        .zIndex(2)
        ResetConfirmSheet(
            isOpen: props.resetConfirmOpen,
            theme: theme,
            onConfirm: {
                store.dispatch(ResetFastThunk())
                store.dispatch(UIAction.resetConfirmClosed)
            },
            onDismiss: { store.dispatch(UIAction.resetConfirmClosed) }
        )
        .zIndex(3)
    }

    // MARK: Copy / formatting

    private func editorial(state: ScreenState, progress: PhaseProgress) -> String {
        switch state {
        case .idle: return PhaseCopy.idle
        case .complete: return PhaseCopy.complete
        case .active: return PhaseCopy.editorial(for: progress.phase)
        case .goalReached: return strings.Editorial.goalReached(Int(props.plan.fastHours))
        case .eating: return PhaseCopy.complete   // eating renders its own editorial in screen()
        }
    }

    // MARK: Goal-reached moment

    /// The screen state derived from the current clock (used off the TimelineView tick).
    private func currentScreenState() -> ScreenState {
        let now = Date()
        return screenState(progress: PhaseProgress.compute(elapsed: props.elapsed(at: now),
                                                           goalHours: props.plan.fastHours),
                           now: now)
    }

    /// Closes the eating window once it has elapsed: the state has already dropped to
    /// idle (see screenState), so we clear the persisted `isEating` flag to match.
    private func reconcileEating(_ state: ScreenState) {
        if props.isEating && state != .eating {
            store.dispatch(TimerAction.eatingEnded)
        }
    }

    /// "0:24" under an hour (M:SS), "2:14" past one (H:MM) — the footer's OVER value.
    private func overtimeShort(_ over: TimeInterval) -> String {
        let total = max(0, Int(over))
        return total < 3600
            ? String(format: "%d:%02d", total / 60, total % 60)
            : String(format: "%d:%02d", total / 3600, (total / 60) % 60)
    }

    /// Drives the seal/halo/sweep for the goal-reached state. Plays the one-shot
    /// moment (+ haptic + analytics) only on a genuine first crossing; a relaunch
    /// mid-overtime (`hasCelebrated` already set) restores the settled end-state.
    private func syncGoalMoment(to state: ScreenState) {
        guard state == .goalReached else { return }
        // iOS renders backgrounded apps (app-switcher snapshots), so a plain state
        // check would burn the one-shot moment — haptic and all — with nobody
        // watching, leaving a settled seal for whoever taps the push later.
        // onChange(scenePhase) above replays this the moment we're visible again.
        guard scenePhase == .active else { return }
        let haloTarget = colorScheme == .dark ? 0.95 : 0.6

        if props.hasCelebrated {
            goalSealScale = 1
            goalHaloOpacity = haloTarget
            goalSweepOpacity = 0
            goalSweepAngle = 0
            // Relaunch mid-overtime: no moment to wait for, the screen is already settled.
            store.dispatch(AppLifecycleAction.goalScreenSettled)
            return
        }

        // Genuine first crossing.
        store.dispatch(TimerAction.goalCelebrated)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        guard !reduceMotion else {
            goalSealScale = 1
            goalHaloOpacity = haloTarget
            goalSweepOpacity = 0
            store.dispatch(AppLifecycleAction.goalScreenSettled)
            return
        }

        goalSweepAngle = 0
        goalSweepOpacity = 1
        goalSealScale = 0.2
        withAnimation(.easeInOut(duration: 1.15)) { goalSweepAngle = 360 }
        withAnimation(.easeOut(duration: 0.35).delay(1.05)) { goalSweepOpacity = 0 }
        withAnimation(.easeOut(duration: 0.7).delay(0.35)) { goalSealScale = 1 }
        withAnimation(.easeOut(duration: 0.9)) { goalHaloOpacity = haloTarget }

        // Let the seal/sweep finish before anything (the review sheet) can cover it.
        // Re-check the state on arrival — the fast may have been ended meanwhile.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard currentScreenState() == .goalReached else { return }
            store.dispatch(AppLifecycleAction.goalScreenSettled)
        }
    }

    private func mealValue(nowMinute: Int) -> String {
        props.isMealFresh ? strings.Meal.justNow : MealMath.fromLabel(ateDay: props.ateDay, ateMin: props.ateMin, nowMinuteOfDay: nowMinute)
    }

    private func mealSubline(nowMinute: Int) -> String? {
        guard !props.isMealFresh else { return nil }
        let from = MealMath.fromLabel(ateDay: props.ateDay, ateMin: props.ateMin, nowMinuteOfDay: nowMinute)
        let note = MealMath.note(ateDay: props.ateDay, ateMin: props.ateMin, nowMinuteOfDay: nowMinute)
        return strings.Meal.fastCountsFrom(from, note)
    }

    private func mealPreview(nowMinute: Int) -> String {
        let from = MealMath.fromLabel(ateDay: props.ateDay, ateMin: props.ateMin, nowMinuteOfDay: nowMinute)
        let note = MealMath.note(ateDay: props.ateDay, ateMin: props.ateMin, nowMinuteOfDay: nowMinute)
        return "\(from) · \(note)"
    }

    /// "8:00 PM" from an epoch timestamp.
    private func clockTime(_ timestamp: Double) -> String {
        guard timestamp > 0 else { return "--" }
        let f = DateFormatter()
        // Keep the region's 12/24h convention (and the device's 24-Hour Time setting)
        // but force Western (Latin) digits, so the footer clock matches the manually
        // built timer/chip numerals instead of showing Eastern-Arabic digits in ar.
        var localeComponents = Locale.Components(locale: .current)
        localeComponents.numberingSystem = Locale.NumberingSystem("latn")
        f.locale = Locale(components: localeComponents)
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: Date(timeIntervalSince1970: timestamp))
    }

    /// "13h 24m" from an elapsed interval.
    private func hoursMinutes(_ elapsed: TimeInterval) -> String {
        let total = max(0, Int(elapsed))
        return strings.Duration.hm(total / 3600, (total / 60) % 60)
    }
}
