import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                timeDisplaySection
                stageIndicatorSection
                buttonsSection
                descriptionSection
            }
        }
        .onAppear {
            viewModel.setupNotifications()
        }
    }
    
    private var timeDisplaySection: some View {
        HStack {
            Button(action: {
                viewModel.adjustTime(by: -10.minTimeInterval)
            }) {
                Image(systemName: "arrow.left")
            }
            .buttonStyle(BorderedButtonStyle())
            
            VStack {
                Text(viewModel.startDateTimeString)
                Text(viewModel.elapsedTimeString)
                    .font(.system(size: 50))
                    .monospacedDigit()
            }
            
            Button(action: {
                viewModel.adjustTime(by: 10.minTimeInterval)
            }) {
                Image(systemName: "arrow.right")
            }
            .buttonStyle(BorderedButtonStyle())
        }
    }
    
    private var stageIndicatorSection: some View {
        let currentStage = TimeStage.determineStage(from: viewModel.elapsedTime)
        
        return HStack {
            Text(currentStage.displayString)
                .font(.system(size: 20))
                .monospacedDigit()
            
            Image(systemName: currentStage.systemImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(currentStage.stageColor)
                .frame(width: 20, height: 20)
            
            if currentStage.startHour != 0 {
                Text(viewModel.currentStageTimeString)
                    .font(.system(size: 20))
                    .monospacedDigit()
            }
        }
    }
    
    private var buttonsSection: some View {
        VStack {
            Button(action: {
                viewModel.startTimer()
            }) {
                Text("Старт")
                    .font(.title2)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isRunning ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            .disabled(viewModel.isRunning)
            
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.resetTimer()
                }) {
                    Text("Сброс")
                        .padding()
                        .font(.title2)
                        .frame(width: 100, height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    viewModel.stopTimer()
                }) {
                    Text("Стоп")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(!viewModel.isRunning ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }.padding(.horizontal)
        }
    }
    
    private var descriptionSection: some View {
        let currentStage = TimeStage.determineStage(from: viewModel.elapsedTime)
        
        return VStack {
            Text(currentStage.description)
                .font(.callout)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
                .padding()
            
            if let extraDescription = currentStage.extraDescription {
                HStack(spacing: 0) {
                    Text("💡")
                        .padding(.leading)
                    
                    Text(extraDescription)
                        .font(.system(size: 16, weight: .bold))
                        .padding()
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .padding()
            }
        }
    }
}
