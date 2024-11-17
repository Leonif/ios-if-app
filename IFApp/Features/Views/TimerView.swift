import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(alignment: .bottom) {
                    TimeControlButton(action: { viewModel.adjustTime(by: -10.minTimeInterval) },
                                      direction: "left")
                    Spacer()
                    TimerDisplay(timeString: viewModel.elapsedTimeString,
                                 dateString: viewModel.startDateTimeString)
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
