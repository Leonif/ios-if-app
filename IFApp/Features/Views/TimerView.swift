import SwiftUI

struct TimerView: View {
    
    @StateObject private var viewModel = TimerViewModel()
    @State var showSources: Bool = false
    
    var progress: Double {
        min(viewModel.elapsedTime / (24 * 3600), 1.0)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                showSources = true
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
        }.padding()
        
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
        .background(Color.backWhite)
        .onAppear {
            viewModel.setupNotifications()
        }
        .sheet(isPresented: $showSources, content: { SourcesView() })
        
    }
}
