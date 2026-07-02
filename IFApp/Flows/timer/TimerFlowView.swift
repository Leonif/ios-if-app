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
import Redux

struct TimerScreenProps: Equatable {
    let isRunning: Bool
    let fastStartTimestamp: Double
    let stagedElapsed: TimeInterval
    let planIdx: Int
    let ateDay: Int
    let ateMin: Int
    let planEditorOpen: Bool
    let mealPickerOpen: Bool
    let reviewPromptOpen: Bool

    init(state: AppState) {
        isRunning = state.timerState.isRunning
        fastStartTimestamp = state.timerState.fastStartTimestamp
        stagedElapsed = state.timerState.stagedElapsed
        planIdx = state.planState.planIdx
        ateDay = state.mealState.ateDay
        ateMin = state.mealState.ateMin
        planEditorOpen = state.uiState.planEditorOpen
        mealPickerOpen = state.uiState.mealPickerOpen
        reviewPromptOpen = state.uiState.reviewPromptOpen
    }

    var plan: Plan { Plan(rawValue: planIdx) ?? .default }
    var isMealFresh: Bool { ateMin < 0 }

    func elapsed(at now: Date) -> TimeInterval {
        isRunning ? max(0, now.timeIntervalSince1970 - fastStartTimestamp) : stagedElapsed
    }
}

private enum ScreenState { case idle, active, complete }

struct TimerFlowView: View {
    private let store: Store<AppState>
    @Environment(\.colorScheme) private var colorScheme
    @State private var props: TimerScreenProps
    @State private var showSources = false

    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: TimerScreenProps(state: store.getCurrentState()))
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        ZStack {
            backgroundLayer(theme: theme)

            if props.isRunning {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    screen(theme: theme, now: ctx.date)
                }
            } else {
                screen(theme: theme, now: Date())
            }

            overlays(theme: theme)
        }
        .sheet(isPresented: $showSources) { SourcesView() }
        .connect(to: store, mapState: { TimerScreenProps(state: $0) }, onPropsChange: { props = $0 })
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
        let state = screenState(progress: progress)
        let nowMinute = Clock.minuteOfDay(now)

        VStack(spacing: 20) {
            TimerHeader(
                plan: props.plan,
                theme: theme,
                onEditPlan: { store.dispatch(UIAction.planEditorOpened) },
                onSettings: { showSources = true }
            )
            .padding(.bottom, 4)

            ZStack {
                PhaseRing(progress: progress.fraction, currentPhase: progress.phase,
                          isComplete: state == .complete, theme: theme)
                ringCenter(state: state, elapsed: elapsed, progress: progress, theme: theme)
            }
            .padding(.vertical, 6)

            EditorialSentence(text: editorial(state: state, progress: progress), theme: theme)

            if state == .active, let next = progress.nextPhase {
                NextPhaseChip(next: next, secondsToNext: progress.secondsToNext, theme: theme)
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
                          isComplete: state == .complete,
                          theme: theme)
                .padding(.top, 2)

            // Push the footer to the bottom; everything above flows from the top.
            Spacer(minLength: 12)

            footer(state: state, elapsed: elapsed, theme: theme)
        }
        .padding(.top, 14)
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func screenState(progress: PhaseProgress) -> ScreenState {
        if !props.isRunning && props.stagedElapsed == 0 { return .idle }
        if progress.isComplete || (!props.isRunning && props.stagedElapsed > 0) { return .complete }
        return .active
    }

    // MARK: Ring center

    @ViewBuilder
    private func ringCenter(state: ScreenState, elapsed: TimeInterval, progress: PhaseProgress, theme: ThemeTokens) -> some View {
        switch state {
        case .idle:
            RingCenterIdle(theme: theme, onStart: { store.dispatch(StartFastThunk()) })
        case .active:
            RingCenterActive(elapsed: elapsed, phase: progress.phase, theme: theme)
        case .complete:
            RingCenterComplete(elapsed: elapsed, theme: theme)
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
        case .complete:
            CompleteFooterCard(
                fasted: hoursMinutes(elapsed),
                windowOpens: strings.Meal.now,
                theme: theme,
                onReset: { store.dispatch(ResetFastThunk()) },
                onStartEating: { store.dispatch(ResetFastThunk()) }
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
        if props.reviewPromptOpen {
            ReviewPromptSheet(
                theme: theme,
                onPositive: { store.dispatch(LeaveReviewThunk()) },
                onDismiss: { store.dispatch(UIAction.reviewPromptClosed) }
            )
            .zIndex(2)
        }
    }

    // MARK: Copy / formatting

    private func editorial(state: ScreenState, progress: PhaseProgress) -> String {
        switch state {
        case .idle: return PhaseCopy.idle
        case .complete: return PhaseCopy.complete
        case .active: return PhaseCopy.editorial(for: progress.phase)
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
