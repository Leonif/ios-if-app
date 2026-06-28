//
//  TimerFlowView.swift
//  IFApp
//
//  Timer screen on Redux: reads a Props projection, dispatches thunks on user actions.
//  Elapsed time is derived from the store's fastStartTimestamp + the current clock,
//  refreshed once per second by TimelineView while a fast is running.
//

import SwiftUI
import Redux

struct TimerProps: Equatable {
    let isRunning: Bool
    let fastStartTimestamp: Double
    let stagedElapsed: TimeInterval

    init(state: AppState) {
        isRunning = state.timerState.isRunning
        fastStartTimestamp = state.timerState.fastStartTimestamp
        stagedElapsed = state.timerState.stagedElapsed
    }

    func elapsed(at now: Date) -> TimeInterval {
        isRunning ? max(0, now.timeIntervalSince1970 - fastStartTimestamp) : stagedElapsed
    }
}

struct TimerFlowView: View {
    private let store: Store<AppState>
    @State private var props: TimerProps
    @State private var showSources = false

    init(store: Store<AppState>) {
        self.store = store
        _props = State(initialValue: TimerProps(state: store.getCurrentState()))
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                if props.isRunning {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        content(elapsed: props.elapsed(at: context.date))
                    }
                } else {
                    content(elapsed: props.stagedElapsed)
                }
            }

            sourcesButton
        }
        .background(Color.backWhite)
        .sheet(isPresented: $showSources) { SourcesView() }
        .connect(to: store, mapState: { TimerProps(state: $0) }, onPropsChange: { props = $0 })
    }

    @ViewBuilder
    private func content(elapsed: TimeInterval) -> some View {
        let stage = TimeStage.determineStage(from: elapsed)
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                TimeControlButton(action: { store.dispatch(AdjustTimeThunk(by: -10.minTimeInterval)) },
                                  direction: "left")
                Spacer()
                CircularProgressView(
                    progress: min(elapsed / (24 * 3600), 1.0),
                    timeString: elapsed.timeString,
                    startTimeString: startTimeString(),
                    currentStage: stage
                )
                Spacer()
                TimeControlButton(action: { store.dispatch(AdjustTimeThunk(by: 10.minTimeInterval)) },
                                  direction: "right")
            }
            .padding(.horizontal)

            PhaseIndicator(phase: stage, elapsedInPhase: stageElapsedString(elapsed: elapsed, stage: stage))

            ControlButtons(
                isRunning: props.isRunning,
                onStart: { store.dispatch(StartFastThunk()) },
                onStop: { store.dispatch(StopFastThunk()) },
                onReset: { store.dispatch(ResetFastThunk()) }
            )

            PhaseDescription(description: stage.description, extraInfo: stage.extraDescription)
        }
        .padding(.top, 42)
    }

    private var sourcesButton: some View {
        HStack {
            Spacer()
            Button(action: {
                showSources = true
                store.dispatch(AppLifecycleAction.sourcesOpened)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 16))
                    Text("Sources")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
    }

    /// Formatted start datetime, shown only while a fast is running (matches legacy behavior).
    private func startTimeString() -> String? {
        guard props.fastStartTimestamp > 0 else { return nil }
        let date = Date(timeIntervalSince1970: props.fastStartTimestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = .current
        return formatter.string(from: date)
    }

    /// Elapsed time within the current stage (since the stage's start hour).
    private func stageElapsedString(elapsed: TimeInterval, stage: TimeStage) -> String {
        let interval = elapsed - TimeInterval(stage.startHour * 3600)
        return interval.timeString
    }
}
