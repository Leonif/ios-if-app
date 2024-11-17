import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Таймер с контролами
                HStack {
                    TimeControlButton(action: { viewModel.adjustTime(by: -10.minTimeInterval) },
                                   direction: "left")
                    
                    TimerDisplay(timeString: viewModel.elapsedTimeString,
                               dateString: viewModel.startDateTimeString)
                    
                    TimeControlButton(action: { viewModel.adjustTime(by: 10.minTimeInterval) },
                                   direction: "right")
                }
                .padding()
                
                // Индикатор фазы
                PhaseIndicator(phase: TimeStage.determineStage(from: viewModel.elapsedTime),
                             elapsedInPhase: viewModel.currentStageTimeString)
                
                // Кнопки управления
                ControlButtons(isRunning: viewModel.isRunning,
                             onStart: viewModel.startTimer,
                             onStop: viewModel.stopTimer,
                             onReset: viewModel.resetTimer)
                
                // Описание фазы
                let currentStage = TimeStage.determineStage(from: viewModel.elapsedTime)
                PhaseDescription(description: currentStage.description,
                               extraInfo: currentStage.extraDescription)
            }
            .padding(.vertical)
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            viewModel.setupNotifications()
        }
    }
}
