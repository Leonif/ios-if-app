//
//  TimerFlowView.swift
//  IFApp
//

import SwiftUI
import UIKit
import Redux

struct TimerFlowView: View {
    private let store: Store<AppState>
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var props: Props
    @State private var showSunnah = false
    @State private var sunnahRequestedFromAbout = false
    @State private var showSources = false
    @State private var showHistory = false
    @State private var historyFocus: UUID?
    @State private var historySource: HistoryEntrySource = .streakBadge

    @State private var goalSealScale: CGFloat = 0
    @State private var goalHaloOpacity: Double = 0
    @State private var goalSweepAngle: Double = 0
    @State private var goalSweepOpacity: Double = 0
    @State private var goalMomentPlayed = false
    @State private var footerHeight: CGFloat = 0

    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: Props(state: store.getCurrentState()))
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        Group {
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
            overlays(theme: theme)
                .animation(.easeOut(duration: 0.3), value: props.streakMilestoneOpen)
                .animation(.easeOut(duration: 0.3), value: props.resetConfirmOpen)
                .animation(.easeOut(duration: 0.3), value: props.endEatingConfirmOpen)
                .animation(.easeOut(duration: 0.3), value: props.notice != nil)
        }
        .sheet(isPresented: $showSunnah) { SunnahFlowView(store: store) }
        .sheet(isPresented: $showSources, onDismiss: openSunnahIfRequested) {
            AboutFlowView(store: store, onSunnah: requestSunnahFromAbout)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: props.offerOpen) { _, isOpen in
            if isOpen {
                sunnahRequestedFromAbout = false
                showSources = false
                showSunnah = false
            }
        }
        .onChange(of: noticeMoment) { _, moment in
            if moment { presentRevocationIfNeutral() }
        }
        .onChange(of: props.isEating) { _, isEating in
            if isEating { scheduleEatingWindowSettled() }
        }
        .navigationDestination(isPresented: $showHistory) {
            HistoryFlowView(store: store, source: historySource, focusRecordID: historyFocus,
                            onStartFast: { store.dispatch(StartFastThunk()) })
        }
        .toolbar(.hidden, for: .navigationBar)
        .connect(to: store, mapState: { Props(state: $0) }, onPropsChange: { props = $0 })
        .onAppear {
            store.dispatch(AppLifecycleAction.themeActive(dark: colorScheme == .dark))
            store.dispatch(AppLifecycleAction.appBecameActive)
            syncGoalMoment(to: props.currentScreenState())
            reconcileEating(props.currentScreenState())
            presentRevocationIfNeutral()
        }
        .onChange(of: colorScheme) { _, new in
            store.dispatch(AppLifecycleAction.themeActive(dark: new == .dark))
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.dispatch(AppLifecycleAction.appBecameActive)
            syncGoalMoment(to: props.currentScreenState())
            reconcileEating(props.currentScreenState())
        }
    }

    // MARK: - Background (phase-reactive)

    @ViewBuilder
    private func backgroundLayer(theme: ThemeTokens) -> some View {
        let state = props.currentScreenState()
        if state == .eating || state == .eatingOver {
            theme.eatingWindowBackground.ignoresSafeArea()
        } else {
            let progress = PhaseProgress.compute(elapsed: props.elapsed(at: Date()), goalHours: props.goalHours)
            theme.phaseBackground(progress.phase.color).ignoresSafeArea()
        }
    }

    // MARK: - Main screen

    @ViewBuilder
    private func screen(theme: ThemeTokens, now: Date) -> some View {
        let elapsed = props.elapsed(at: now)
        let progress = PhaseProgress.compute(elapsed: elapsed, goalHours: props.goalHours)
        let state = props.screenState(at: now)
        let nowMinute = Clock.minuteOfDay(now)

        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let headerTop: CGFloat = 14
            let headerHeight: CGFloat = 34
            let headerGap: CGFloat = 24

            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if state == .eating {
                        VStack(spacing: 20) {
                            EatingWindowCard(remaining: props.eatingRemaining(at: now),
                                             closesAt: clockTime(props.eatingEndTimestamp),
                                             theme: theme)
                                .padding(.vertical, 6)

                            EditorialSentence(text: strings.Editorial.windowOpen, theme: theme)
                        }
                    } else if state == .eatingOver {
                        VStack(spacing: 20) {
                            EatingOverCard(sinceClose: props.eatingOverElapsed(at: now), theme: theme)
                                .padding(.vertical, 6)

                            EditorialSentence(text: strings.Editorial.windowClosed, theme: theme)

                            LastMealPill(
                                valueText: mealValue(nowMinute: nowMinute),
                                subline: mealSubline(nowMinute: nowMinute),
                                theme: theme,
                                onTap: openMealPicker
                            )
                        }
                    } else {
                        VStack(spacing: 20) {
                            ZStack {
                                PhaseRing(progress: progress.fraction, currentPhase: progress.phase,
                                          isComplete: progress.isComplete, theme: theme,
                                          diameter: 280,
                                          sealDiameter: state == .goalReached
                                              ? GoalMomentView.sealDiameter : 0,
                                          showsHeadDot: state != .complete)
                                if state == .goalReached {
                                    GoalMomentView(sealScale: goalSealScale, haloOpacity: goalHaloOpacity,
                                                   sweepAngle: goalSweepAngle, sweepOpacity: goalSweepOpacity,
                                                   theme: theme, diameter: 280)
                                }
                                ringCenter(state: state, elapsed: elapsed, progress: progress, theme: theme)
                            }
                            .padding(.vertical, 6)

                            EditorialSentence(text: editorial(state: state, progress: progress, elapsed: elapsed),
                                              theme: theme)

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
                                    onTap: openMealPicker
                                )
                            }

                            PhaseTimeline(currentPhase: progress.phase,
                                          currentFill: progress.fraction * 4 - Double(progress.phase.rawValue),
                                          isComplete: progress.isComplete,
                                          theme: theme)
                                .padding(.top, 2)

                            if state == .complete {
                                HistoryLink(title: strings.History.savedToHistory, theme: theme,
                                            identifier: "timer.savedToHistory",
                                            tint: theme.mut, minHeight: 44,
                                            action: { openHistory(from: .completeCard) })
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, headerTop + headerHeight + headerGap)
                .padding(.bottom, 12 + footerHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .top) {
                TimerHeader(
                    plan: props.plan,
                    streak: props.streak.display(at: now),
                    hasRecords: props.hasRecords,
                    showsPro: showsProEntry(state: state),
                    theme: theme,
                    onEditPlan: { store.dispatch(UIAction.planEditorOpened) },
                    onHistory: { openHistory(from: .streakBadge) },
                    onPro: { store.dispatch(ProAction.offerOpened(trigger: .home)) },
                    onSettings: openSources
                )
                .padding(.top, headerTop)
                .padding(.horizontal, 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer(state: state, elapsed: elapsed, theme: theme)
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(insets.bottom, 32))
                    .frame(maxWidth: .infinity)
                    .background(theme.backgroundBase)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: FooterHeightKey.self, value: proxy.size.height)
                    })
            }
            .onPreferenceChange(FooterHeightKey.self) { height in
                footerHeight = height
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onChange(of: state) { _, newState in
            syncGoalMoment(to: newState)
            reconcileEating(newState)
        }
        .onAppear {
            syncGoalMoment(to: state)
            reconcileEating(state)
        }
    }

    // MARK: - Ring center

    @ViewBuilder
    private func ringCenter(state: TimerScreenState, elapsed: TimeInterval, progress: PhaseProgress, theme: ThemeTokens) -> some View {
        switch state {
        case .idle:
            RingCenterIdle(theme: theme, onStart: { store.dispatch(StartFastThunk()) })
        case .active:
            RingCenterActive(elapsed: elapsed, phase: progress.phase, theme: theme)
        case .goalReached:
            RingCenterGoalReached(elapsed: elapsed, goalSeconds: props.goalHours * 3600, theme: theme)
        case .complete:
            RingCenterComplete(elapsed: elapsed, goalReached: progress.isComplete, theme: theme)
        case .eating, .eatingOver:
            EmptyView()
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private func footer(state: TimerScreenState, elapsed: TimeInterval, theme: ThemeTokens) -> some View {
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
                isEndFastEnabled: !props.endFast.isOpen,
                onEndFast: { store.dispatch(OpenEndFastThunk()) }
            )
        case .goalReached:
            GoalReachedFooterCard(
                fasted: hoursMinutes(elapsed),
                goal: hoursMinutes(props.goalHours * 3600),
                over: "+" + overtimeShort(elapsed - props.goalHours * 3600),
                theme: theme,
                isEndFastEnabled: !props.endFast.isOpen,
                onReset: { store.dispatch(UIAction.resetConfirmOpened) },
                onEndFast: { store.dispatch(OpenEndFastThunk()) }
            )
        case .complete:
            CompleteFooterCard(
                fasted: hoursMinutes(elapsed),
                windowOpens: strings.Meal.now,
                consequence: consequenceLine(elapsed: elapsed),
                theme: theme,
                onResume: { store.dispatch(ResumeFastThunk()) },
                onSkip: { store.dispatch(ResetFastThunk()) },
                onStartEating: { store.dispatch(StartEatingThunk()) }
            )
        case .eating:
            EatingFooterCard(
                lastFast: props.lastFastDuration.map(hoursMinutes),
                theme: theme,
                onSkip: { store.dispatch(UIAction.endEatingConfirmOpened) },
                onStartFast: { store.dispatch(StartFastThunk()) },
                onHistory: { openHistory(from: .eatingWindow) }
            )
        case .eatingOver:
            EatingOverFooterCard(
                theme: theme,
                onSkip: {
                    store.dispatch(TimerAction.eatingEnded)
                    store.dispatch(MealAction.cleared)
                },
                onContinue: { store.dispatch(ContinueFastingThunk()) }
            )
        }
    }

    private func consequenceLine(elapsed: TimeInterval) -> String {
        guard !PhaseProgress.compute(elapsed: elapsed, goalHours: props.goalHours).isComplete else {
            return strings.Footer.consequenceDefault
        }
        return strings.Footer.consequenceNearGoal(hoursMinutes(elapsed))
    }

    // MARK: - Pro

    private var screenIsClear: Bool {
        props.notice == nil
            && !props.offerOpen
            && !showSources
            && !showSunnah
            && !showHistory
            && !props.planEditorOpen
            && !props.mealPickerOpen
            && !props.streakMilestoneOpen
            && !props.resetConfirmOpen
            && !props.endEatingConfirmOpen
            && !props.endFast.isOpen
    }

    private var noticeMoment: Bool {
        props.revocationPending && screenIsClear && props.currentScreenState() == .idle
    }

    private func showsProEntry(state: TimerScreenState) -> Bool {
        props.isVerifiedFree && state != .goalReached && state != .complete
    }

    private func openSources() {
        store.dispatch(AppLifecycleAction.sourcesOpened)
        showSources = true
    }

    private func requestSunnahFromAbout() {
        sunnahRequestedFromAbout = true
        showSources = false
    }

    private func openSunnahIfRequested() {
        guard sunnahRequestedFromAbout else { return }
        sunnahRequestedFromAbout = false
        store.dispatch(AppLifecycleAction.sunnahOpened(source: .about))
        showSunnah = true
    }

    private static let autoOfferDelay: TimeInterval = 0.42

    private func scheduleEatingWindowSettled() {
        guard props.currentScreenState() == .eating else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.autoOfferDelay) {
            guard scenePhase == .active,
                  props.currentScreenState() == .eating,
                  screenIsClear
            else { return }
            if props.autoOfferPending {
                store.dispatch(ProAction.offerOpened(trigger: .fastFinished))
            } else {
                store.dispatch(AppLifecycleAction.eatingWindowSettled)
            }
        }
    }

    private func confirmPlan(hours: Int) {
        guard Plan(hours: hours).allowed(isPro: props.isPro) else {
            store.dispatch(ProAction.offerOpened(trigger: .planCustom))
            return
        }
        store.dispatch(PlanAction.selected(hours: hours))
        store.dispatch(UIAction.planEditorClosed)
    }

    private func presentRevocationIfNeutral() {
        guard noticeMoment else { return }
        store.dispatch(ProAction.noticeShown(.entitlementRevoked))
    }

    private func openHistory(from source: HistoryEntrySource, focusing recordID: UUID? = nil) {
        historySource = source
        historyFocus = recordID
        showHistory = true
    }

    // MARK: - Overlays (sheets)

    @ViewBuilder
    private func overlays(theme: ThemeTokens) -> some View {
        if props.planEditorOpen {
            PlanEditorSheet(
                plan: props.plan,
                isPro: props.isPro,
                theme: theme,
                onSelect: { store.dispatch(PlanAction.selected(hours: $0)) },
                onDone: confirmPlan,
                onClose: { store.dispatch(UIAction.planEditorClosed) },
                onSunnah: {
                    store.dispatch(UIAction.planEditorClosed)
                    store.dispatch(AppLifecycleAction.sunnahOpened(source: .planEditor))
                    showSunnah = true
                }
            )
            .zIndex(1)
        }
        if props.mealPickerOpen {
            let nowMinute = Clock.minuteOfDay()
            let mins = props.minutesAgo
            let moment = MealMath.moment(minutesAgo: mins, nowMinuteOfDay: nowMinute)
            LastMealPickerSheet(
                minutesAgo: mins,
                nowMinuteOfDay: nowMinute,
                readout: MealMath.agoLabel(minutesAgo: mins),
                absoluteLabel: MealMath.absoluteLabel(ateDay: moment.ateDay, ateMin: moment.ateMin),
                overline: props.currentScreenState() == .eatingOver ? strings.Meal.windowClosedOverline : nil,
                selectedChip: props.chipIdx,
                theme: theme,
                onChip: { store.dispatch(PickMealChipThunk($0)) },
                onScrub: { store.dispatch(MealAction.scrubbed(minutesAgo: $0)) },
                onFeedback: { store.dispatch(MealFeedbackThunk($0)) },
                onExactTime: { store.dispatch(SetExactMealTimeThunk($0)) },
                onConfirm: { store.dispatch(ConfirmLastMealThunk()) },
                onClose: {
                    store.dispatch(MealAction.pickerDismissed)
                    store.dispatch(UIAction.mealPickerClosed)
                }
            )
            .zIndex(1)
        }
        if props.endFast.isOpen {
            EndFastSheet(
                state: props.endFast,
                now: Clock.now().timeIntervalSince1970,
                theme: theme,
                onChip: { store.dispatch(EndFastChipThunk(offset: $0)) },
                onStep: { store.dispatch(EndFastStepThunk(minutes: $0)) },
                onConfirm: { store.dispatch(ConfirmEndFastThunk()) },
                onKeepFast: { store.dispatch(EndFastAction.closed) },
                onPickAnotherTime: { store.dispatch(EndFastAction.refusalWithdrawn) },
                onOpenConflict: { record in
                    store.dispatch(EndFastAction.closed)
                    openHistory(from: .endFastOverlap, focusing: record.id)
                },
                onClose: { store.dispatch(EndFastAction.closed) }
            )
            .zIndex(1)
        }
        StreakMilestoneSheet(
            isOpen: props.streakMilestoneOpen,
            days: props.streak.count,
            theme: theme,
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
        EndEatingConfirmSheet(
            isOpen: props.endEatingConfirmOpen,
            theme: theme,
            onConfirm: {
                store.dispatch(TimerAction.eatingEnded)
                store.dispatch(UIAction.endEatingConfirmClosed)
            },
            onDismiss: { store.dispatch(UIAction.endEatingConfirmClosed) }
        )
        .zIndex(3)
        ProNoticeSheet(
            notice: props.notice,
            theme: theme,
            onDismiss: { store.dispatch(ProAction.noticeDismissed) }
        )
        .zIndex(4)
    }

    // MARK: - Copy / formatting

    private func editorial(state: TimerScreenState, progress: PhaseProgress,
                           elapsed: TimeInterval) -> String {
        switch state {
        case .idle: return PhaseCopy.idle
        case .complete: return PhaseCopy.complete
        case .active: return PhaseCopy.editorial(for: progress.phase)
        case .goalReached:
            let over = elapsed - props.goalHours * 3600
            guard over >= EndFastState.overtimeNeutralThreshold else {
                return strings.Editorial.goalReached(Int(props.goalHours))
            }
            let total = max(0, Int(over))
            return strings.EndFast.timerRanPast(strings.Duration.hm(total / 3600, (total / 60) % 60))
        case .eating: return strings.Editorial.windowOpen
        case .eatingOver: return strings.Editorial.windowClosed
        }
    }

    // MARK: - Goal-reached moment

    private func reconcileEating(_ state: TimerScreenState) {
        if props.endEatingConfirmOpen && state != .eating {
            store.dispatch(UIAction.endEatingConfirmClosed)
        }
        if props.isEating && state != .eating && state != .eatingOver {
            store.dispatch(TimerAction.eatingEnded)
            store.dispatch(MealAction.cleared)
        }
        if state == .eatingOver && props.isMealFresh {
            store.dispatch(SeedLastMealFromWindowCloseThunk())
        }
    }

    private func overtimeShort(_ over: TimeInterval) -> String {
        let total = max(0, Int(over))
        return total < 3600
            ? String(format: "%d:%02d", total / 60, total % 60)
            : String(format: "%d:%02d", total / 3600, (total / 60) % 60)
    }

    private func syncGoalMoment(to state: TimerScreenState) {
        guard state == .goalReached else {
            goalMomentPlayed = false
            return
        }
        guard scenePhase == .active else { return }
        guard !goalMomentPlayed else { return }
        goalMomentPlayed = true
        let haloTarget = colorScheme == .dark ? 0.95 : 0.6

        if props.hasCelebrated {
            goalSealScale = 1
            goalHaloOpacity = haloTarget
            goalSweepOpacity = 0
            goalSweepAngle = 0
            store.dispatch(AppLifecycleAction.goalScreenSettled)
            return
        }

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard props.currentScreenState() == .goalReached else { return }
            store.dispatch(AppLifecycleAction.goalScreenSettled)
        }
    }

    private func openMealPicker() {
        store.dispatch(MealAction.pickerOpened)
        store.dispatch(UIAction.mealPickerOpened)
    }

    private func mealValue(nowMinute: Int) -> String {
        props.isMealFresh ? strings.Meal.justNow : MealMath.fromLabel(minutesAgo: props.minutesAgo, nowMinuteOfDay: nowMinute)
    }

    private func mealSubline(nowMinute: Int) -> String? {
        guard !props.isMealFresh else { return nil }
        let from = MealMath.fromLabel(minutesAgo: props.minutesAgo, nowMinuteOfDay: nowMinute)
        let note = MealMath.note(minutesAgo: props.minutesAgo)
        return strings.Meal.fastCountsFrom(from, note)
    }

    private func clockTime(_ timestamp: Double) -> String {
        guard timestamp > 0 else { return "--" }
        let f = DateFormatter()
        f.locale = .latinDigits
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: Date(timeIntervalSince1970: timestamp))
    }

    private func hoursMinutes(_ elapsed: TimeInterval) -> String {
        let total = max(0, Int(elapsed))
        return strings.Duration.hm(total / 3600, (total / 60) % 60)
    }
}
