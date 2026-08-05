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
    /// Epoch seconds the eating window closes — projected from the timer state, not
    /// recomputed here, so the screen and the close push agree on the moment.
    let eatingEndTimestamp: Double
    /// The plan the user has selected — what the header pill shows and the editor edits.
    let plan: Plan
    /// The goal of the cycle on screen. Not the same fact as `plan`: a plan changed
    /// mid-fast (or a custom goal whose entitlement went away) leaves the fast in
    /// flight running to the goal it started with.
    let goalHours: Double
    let ateDay: Int
    let ateMin: Int
    let streak: StreakStatus
    /// The header pill only exists once there is a record to open.
    let hasRecords: Bool
    /// Length of the newest finished fast — the eating window's link into history.
    let lastFastDuration: TimeInterval?
    let planEditorOpen: Bool
    let mealPickerOpen: Bool
    let streakMilestoneOpen: Bool
    let resetConfirmOpen: Bool
    /// Whether the lock shows on the custom row, and whether the offer is up.
    let isPro: Bool
    let offerOpen: Bool
    /// Whether the selected plan may be confirmed as it stands — projected from
    /// `AppState`, not re-derived here, so the editor and the next start agree.
    let selectedPlanAllowed: Bool
    /// The one-time notice on screen, and the one still waiting for a neutral moment.
    let notice: ProNotice?
    let revocationPending: Bool

    init(state: AppState) {
        isRunning = state.timerState.isRunning
        fastStartTimestamp = state.timerState.fastStartTimestamp
        stagedElapsed = state.timerState.stagedElapsed
        hasCelebrated = state.timerState.hasCelebrated
        isEating = state.timerState.isEating
        eatingEndTimestamp = state.timerState.eatingEndTimestamp(plan: state.activePlan)
        streak = state.timerState.streak
        hasRecords = !state.historyState.records.isEmpty
        lastFastDuration = state.historyState.records
            .max(by: { $0.endTimestamp < $1.endTimestamp })?
            .duration
        plan = state.planState.plan
        goalHours = state.activeGoalHours
        ateDay = state.mealState.ateDay
        ateMin = state.mealState.ateMin
        planEditorOpen = state.uiState.planEditorOpen
        mealPickerOpen = state.uiState.mealPickerOpen
        streakMilestoneOpen = state.uiState.streakMilestoneOpen
        resetConfirmOpen = state.uiState.resetConfirmOpen
        isPro = state.proState.isPro
        offerOpen = state.proState.isOfferOpen
        selectedPlanAllowed = state.selectedPlanAllowed
        notice = state.proState.notice
        revocationPending = state.proState.revocationPending
    }

    var isMealFresh: Bool { ateMin < 0 }

    func elapsed(at now: Date) -> TimeInterval {
        isRunning ? max(0, now.timeIntervalSince1970 - fastStartTimestamp) : stagedElapsed
    }

    /// Seconds left in the eating window (until the next fast should start).
    func eatingRemaining(at now: Date) -> TimeInterval {
        max(0, eatingEndTimestamp - now.timeIntervalSince1970)
    }

    /// Seconds since the eating window closed (the window-closed count-up).
    func eatingOverElapsed(at now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince1970 - eatingEndTimestamp)
    }
}

private enum ScreenState { case idle, active, goalReached, complete, eating, eatingOver }

struct TimerFlowView: View {
    private let store: Store<AppState>
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var props: TimerScreenProps
    @State private var showSources = false
    @State private var showHistory = false
    /// Which entry point opened the history: it names the analytics source, and the
    /// eating-window one also decides that the record just closed opens with it.
    @State private var historySource: HistoryEntrySource = .streakBadge

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
                .animation(.easeOut(duration: 0.3), value: props.streakMilestoneOpen)
                .animation(.easeOut(duration: 0.3), value: props.resetConfirmOpen)
                .animation(.easeOut(duration: 0.3), value: props.notice != nil)
        }
        // The offer is a full surface rather than a `fullScreenCover` because its
        // appearance is specified in numbers — 28pt of travel over 420ms on a curve
        // with no overshoot — and the system cover brings its own.
        .overlay {
            if props.offerOpen {
                PaywallFlowView(store: store, phaseColor: offerPhaseColor())
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: props.offerOpen)
        .sheet(isPresented: $showSources) {
            AboutFlowView(store: store).presentationDragIndicator(.visible)
        }
        // The About sheet is one of the doors into the offer, and the offer is behind
        // it. Opening one closes the other.
        .onChange(of: props.offerOpen) { _, isOpen in
            if isOpen { showSources = false }
        }
        // Edge 6. The nearest neutral moment: not over a running fast, not on the
        // complete state, not over the goal animation. Nothing is lost by waiting —
        // the lock is already back, this is only the sentence about it.
        .onChange(of: noticeMoment) { _, moment in
            if moment { presentRevocationIfNeutral() }
        }
        // History is a push, not a sheet: it is deeper into the app, not a dialog
        // over it.
        .navigationDestination(isPresented: $showHistory) {
            HistoryFlowView(store: store, source: historySource,
                            onStartFast: { store.dispatch(StartFastThunk()) })
        }
        .toolbar(.hidden, for: .navigationBar)
        .connect(to: store, mapState: { TimerScreenProps(state: $0) }, onPropsChange: { props = $0 })
        .onAppear {
            store.dispatch(AppLifecycleAction.themeActive(dark: colorScheme == .dark))
            store.dispatch(AppLifecycleAction.appBecameActive)
            // Restore the settled overtime end-state on a relaunch mid-overtime
            // (onChange below won't fire for the initial state).
            syncGoalMoment(to: currentScreenState())
            // An eating window may have elapsed while the app was closed.
            reconcileEating(currentScreenState())
            // A refund can land while the app is shut; the neutral moment is then
            // this one, and `onChange` below would never fire for it.
            presentRevocationIfNeutral()
        }
        .onChange(of: colorScheme) { _, new in
            store.dispatch(AppLifecycleAction.themeActive(dark: new == .dark))
        }
        .onChange(of: scenePhase) { _, phase in
            // The goal can be crossed while we're backgrounded; the moment waits
            // here until the user is actually looking at the screen.
            guard phase == .active else { return }
            // Every foreground counts as an "open" for the review fallback (the
            // cold start is covered by onAppear below — the initial scenePhase
            // may already be .active, so this onChange alone can miss it).
            store.dispatch(AppLifecycleAction.appBecameActive)
            syncGoalMoment(to: currentScreenState())
            reconcileEating(currentScreenState())
        }
    }

    // MARK: Background (phase-reactive)

    @ViewBuilder
    private func backgroundLayer(theme: ThemeTokens) -> some View {
        // An open window has no phase to react to: its elapsed is zero, which would
        // tint the screen amber (Fed) as if a meal had just landed. The phase timeline
        // is already gone from this state — the backdrop follows it.
        //
        // `.eatingOver` sits in the same gap: the window has closed but the next fast
        // is not started, so there is no phase scale on screen and no elapsed to derive
        // a phase from — same reasoning, same neutral backdrop.
        let state = currentScreenState()
        if state == .eating || state == .eatingOver {
            theme.eatingWindowBackground.ignoresSafeArea()
        } else {
            let progress = PhaseProgress.compute(elapsed: props.elapsed(at: Date()), goalHours: props.goalHours)
            theme.phaseBackground(progress.phase.color).ignoresSafeArea()
        }
    }

    // MARK: Main screen

    @ViewBuilder
    private func screen(theme: ThemeTokens, now: Date) -> some View {
        let elapsed = props.elapsed(at: now)
        let progress = PhaseProgress.compute(elapsed: elapsed, goalHours: props.goalHours)
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
                            EatingWindowCard(remaining: props.eatingRemaining(at: now),
                                             closesAt: clockTime(props.eatingEndTimestamp),
                                             theme: theme)
                                .padding(.vertical, 6)

                            EditorialSentence(text: strings.Editorial.windowOpen, theme: theme)
                        }
                    } else if state == .eatingOver {
                        // Window closed: the count-up is already the next fast in waiting.
                        // The Last-meal control (seeded to the close moment) sets where
                        // "Continue fasting" backdates to.
                        VStack(spacing: 20) {
                            EatingOverCard(sinceClose: props.eatingOverElapsed(at: now), theme: theme)
                                .padding(.vertical, 6)

                            EditorialSentence(text: strings.Editorial.windowClosed, theme: theme)

                            LastMealPill(
                                valueText: mealValue(nowMinute: nowMinute),
                                subline: mealSubline(nowMinute: nowMinute),
                                theme: theme,
                                onTap: { store.dispatch(OpenMealPickerThunk()) }
                            )
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
                    streak: props.streak.displayed(at: now),
                    hasRecords: props.hasRecords,
                    theme: theme,
                    onEditPlan: { store.dispatch(UIAction.planEditorOpened) },
                    onHistory: { openHistory(from: .streakBadge) },
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
        // An open eating window shows the countdown until it closes. Once closed, the
        // chain screen (count-up + Continue fasting) holds for 24h, then falls to idle.
        if props.isEating {
            if props.eatingRemaining(at: now) > 0 { return .eating }
            return props.eatingOverElapsed(at: now) < 24 * 3600 ? .eatingOver : .idle
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
            RingCenterGoalReached(elapsed: elapsed, goalSeconds: props.goalHours * 3600, theme: theme)
        case .complete:
            RingCenterComplete(elapsed: elapsed, theme: theme)
        case .eating, .eatingOver:
            // The eating window / window-closed states render their own ring-free
            // cards (see screen()).
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
                goalLabel: strings.Duration.goalHours(Int(props.goalHours)),
                goalAt: clockTime(props.fastStartTimestamp + props.goalHours * 3600),
                theme: theme,
                onEndFast: { store.dispatch(StopFastThunk()) }
            )
        case .goalReached:
            GoalReachedFooterCard(
                fasted: hoursMinutes(elapsed),
                goal: hoursMinutes(props.goalHours * 3600),
                over: "+" + overtimeShort(elapsed - props.goalHours * 3600),
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
                onStartEating: { store.dispatch(StartEatingThunk()) },
                onHistory: { openHistory(from: .completeCard) }
            )
        case .eating:
            EatingFooterCard(
                lastFast: props.lastFastDuration.map(hoursMinutes),
                theme: theme,
                onSkip: { store.dispatch(TimerAction.eatingEnded) },
                onStartFast: { store.dispatch(StartFastThunk()) },
                onHistory: { openHistory(from: .eatingWindow) }
            )
        case .eatingOver:
            EatingOverFooterCard(
                theme: theme,
                onSkip: {
                    store.dispatch(TimerAction.eatingEnded)
                    // Drop the seeded window-close time so idle starts fresh.
                    store.dispatch(MealAction.cleared)
                },
                onContinue: { store.dispatch(ContinueFastingThunk()) }
            )
        }
    }

    // MARK: Pro

    /// True when the entitlement notice is due and the screen is a place to say it.
    /// Neutral means nothing is in flight: no fast running, no completed fast waiting
    /// to be acknowledged, no eating window counting down, and no offer or notice
    /// already on screen.
    private var noticeMoment: Bool {
        props.revocationPending
            && props.notice == nil
            && !props.offerOpen
            // The notice is an overlay on this screen, so anything presented above it
            // would swallow it — and the flag is spent the moment it is shown. The
            // About sheet is the likeliest one: it is where a refund is noticed.
            && !showSources
            && !showHistory
            && !props.planEditorOpen
            && !props.mealPickerOpen
            && !props.streakMilestoneOpen
            && !props.resetConfirmOpen
            && currentScreenState() == .idle
    }

    /// Confirming the plan. A custom length without Pro is where the lock actually
    /// bites — the picker turned freely up to here. The editor deliberately stays
    /// open behind the offer: someone who came to change their plan should not be
    /// returned to the timer to start over.
    private func confirmPlan() {
        if !props.selectedPlanAllowed {
            store.dispatch(ProAction.offerOpened(trigger: .planCustom))
        } else {
            store.dispatch(UIAction.planEditorClosed)
        }
    }

    private func presentRevocationIfNeutral() {
        guard noticeMoment else { return }
        store.dispatch(ProAction.noticeShown(.entitlementRevoked))
    }

    /// The phase tint the offer inherits — the phase of the screen it was called
    /// from. An open or closed eating window has no phase on screen, and the offer
    /// takes the same neutral green the backdrop behind it already uses.
    private func offerPhaseColor() -> Color {
        let state = currentScreenState()
        guard state != .eating, state != .eatingOver else { return Phase.fat.color }
        return PhaseProgress.compute(elapsed: props.elapsed(at: Date()),
                                     goalHours: props.goalHours).phase.color
    }

    private func openHistory(from source: HistoryEntrySource) {
        historySource = source
        showHistory = true
    }

    // MARK: Overlays (sheets)

    @ViewBuilder
    private func overlays(theme: ThemeTokens) -> some View {
        if props.planEditorOpen {
            PlanEditorSheet(
                plan: props.plan,
                isPro: props.isPro,
                theme: theme,
                onSelect: { store.dispatch(PlanAction.selected(hours: $0)) },
                onDone: confirmPlan,
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
        StreakMilestoneSheet(
            isOpen: props.streakMilestoneOpen,
            days: props.streak.count,
            theme: theme,
            // ReviewMiddleware listens for this close — the native review request
            // may follow once the milestone moment is fully over.
            onDismiss: { store.dispatch(UIAction.streakMilestoneClosed) }
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
        ProNoticeSheet(
            notice: props.notice,
            theme: theme,
            onDismiss: { store.dispatch(ProAction.noticeDismissed) }
        )
        .zIndex(4)
    }

    // MARK: Copy / formatting

    private func editorial(state: ScreenState, progress: PhaseProgress) -> String {
        switch state {
        case .idle: return PhaseCopy.idle
        case .complete: return PhaseCopy.complete
        case .active: return PhaseCopy.editorial(for: progress.phase)
        case .goalReached: return strings.Editorial.goalReached(Int(props.goalHours))
        case .eating: return strings.Editorial.windowOpen   // eating renders its own editorial in screen()
        case .eatingOver: return strings.Editorial.windowClosed
        }
    }

    // MARK: Goal-reached moment

    /// The screen state derived from the current clock (used off the TimelineView tick).
    private func currentScreenState() -> ScreenState {
        let now = Date()
        return screenState(progress: PhaseProgress.compute(elapsed: props.elapsed(at: now),
                                                           goalHours: props.goalHours),
                           now: now)
    }

    /// Keeps the persisted eating flag and the Last-meal control in step with the
    /// derived state. An elapsed window holds `isEating` through `.eatingOver` (the
    /// chain screen is computed from the same timestamps); only the 24h timeout
    /// drops to idle, clearing the flag and the seeded meal time. Entering
    /// `.eatingOver` seeds the Last-meal control to the window close moment, so
    /// "Continue fasting" backdates from there by default.
    private func reconcileEating(_ state: ScreenState) {
        if props.isEating && state != .eating && state != .eatingOver {
            store.dispatch(TimerAction.eatingEnded)
            store.dispatch(MealAction.cleared)
        }
        if state == .eatingOver && props.isMealFresh {
            store.dispatch(SeedLastMealFromWindowCloseThunk())
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

        // Genuine first crossing. The thunk stamps the day key (not the reducer, not
        // this frame) from the fast's own start + goal, so a fast crossing midnight
        // credits the day the goal was reached — the same day history credits it to.
        store.dispatch(CelebrateGoalThunk())
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
        // Keeps the region's 12/24h convention (and the device's 24-Hour Time setting)
        // while forcing Western (Latin) digits, so the footer clock matches the
        // manually built timer/chip numerals instead of Eastern-Arabic digits in ar.
        f.locale = .latinDigits
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
