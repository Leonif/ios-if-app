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
            Button("Sources") {
                showSources = true
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


struct SourcesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Cautions.disclaimer)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                
                let link1 = "https://pubmed.ncbi.nlm.nih.gov/22248338/"
                Text("Sources: ")
                    .font(.largeTitle)
                Text("1. Glycogen and its metabolism: some new developments and old themes - [View Study](\(link1)")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        if let url = URL(string: link1) {
                            UIApplication.shared.open(url)
                        }
                    }
                let link2 = "https://pubmed.ncbi.nlm.nih.gov/28459931/"
                Text("2. Effect of Alternate-Day Fasting on Weight Loss, Weight Maintenance, and Cardioprotection Among Metabolically Healthy Obese Adults: A Randomized Clinical Trial - [View Study](\(link2)")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        if let url = URL(string: link2) {
                            UIApplication.shared.open(url)
                        }
                    }
                
                let link3 = "https://www.nature.com/articles/s41467-020-14384-z"
                Text("3. Fasting-induced FGF21 signaling activates hepatic autophagy and lipid degradation via JMJD3 histone demethylase - [View Study](\(link3)")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        if let url = URL(string: link3) {
                            UIApplication.shared.open(url)
                        }
                    }
                
                let link4 = "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/#:~:text=In%20summary%2C%20intermittent%20fasting%20has,levels%20of%20leptin%20and%20adiponectin."
                Text("4. Intermittent Fasting and Metabolic Health - [View Study](\(link4)")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        if let url = URL(string: link4) {
                            UIApplication.shared.open(url)
                        }
                    }
            }
            
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
}
