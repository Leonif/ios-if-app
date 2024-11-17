import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    var progress: Double {
        min(viewModel.elapsedTime / (24 * 3600), 1.0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(alignment: .center) {
                    TimeControlButton(action: { viewModel.adjustTime(by: -10.minTimeInterval) },
                                      direction: "left")
                    Spacer()
                    CircularProgressView(
                        progress: progress,
                        timeString: viewModel.elapsedTimeString,
                        startTimeString: viewModel.startDateTimeString,
                        currentStage: TimeStage.determineStage(from: viewModel.elapsedTime)
                    )
                    Spacer()
                    TimeControlButton(action: { viewModel.adjustTime(by: 10.minTimeInterval) },
                                      direction: "right")
                }
                .padding(.horizontal)
                
                PhaseIndicator(phase: TimeStage.determineStage(from: viewModel.elapsedTime),
                             elapsedInPhase: viewModel.currentStageTimeString)
                
                ControlButtons(isRunning: viewModel.isRunning,
                             onStart: viewModel.startTimer,
                             onStop: viewModel.stopTimer,
                             onReset: viewModel.resetTimer)
                
                let currentStage = TimeStage.determineStage(from: viewModel.elapsedTime)
                PhaseDescription(
                    description: currentStage.description,
                    extraInfo: currentStage.extraDescription
                )
            }
        }
        .background(Color.white)
        .onAppear {
            viewModel.setupNotifications()
        }
    }
}


