import SwiftUI

struct TimerView: View {
    @AppStorage("elapsed_time") private var savedElapsedTime: Double = 0
    @AppStorage("is_running") private var savedIsRunning: Bool = false
    @AppStorage("background_date") private var savedBackgroundDate: Double = 0
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var backgroundDate: Date?
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image(systemName: stageImage(from: elapsedTime))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(stageColor(from: elapsedTime))
                .frame(width: 40, height: 40)
            
            Text(stageString(from: elapsedTime))
                .font(.system(size: 30))
                .monospacedDigit()
            
            Text(timeString(from: elapsedTime))
                .font(.system(size: 50))
                .monospacedDigit()
            
            Button(action: {
                startTimer()
            }) {
                Text("Старт")
                    .font(.title2)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(isRunning ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            .disabled(isRunning)
            
            HStack(spacing: 16) {
                Button(action: {
                    stopTimer()
                }) {
                    Text("Стоп")
                        .font(.title2)
                        .frame(width: 100, height: 44)
                        .background(!isRunning ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isRunning)
                
                Button(action: {
                    resetTimer()
                }) {
                    Text("Сброс")
                        .padding()
                        .font(.title2)
                        .frame(width: 100, height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Text(stageDescription(from: elapsedTime))
                .font(.callout)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
                .padding()
            
            if let extraDescription = stageExtraDescription(from: elapsedTime) {
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
        
        .onAppear {
            setupNotifications()
            restoreState()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            if isRunning {
                backgroundDate = Date()
                savedBackgroundDate = backgroundDate?.timeIntervalSince1970 ?? 0
                timer?.invalidate()
                timer = nil
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            if isRunning {
                let savedDate = Date(timeIntervalSince1970: savedBackgroundDate)
                let timeInterval = Date().timeIntervalSince(savedDate)
                elapsedTime += timeInterval
                savedElapsedTime = elapsedTime
                startTimer()
            }
        }
    }
    
    private func restoreState() {
        elapsedTime = savedElapsedTime
        isRunning = savedIsRunning
        
        if isRunning {
            if savedBackgroundDate > 0 {
                let savedDate = Date(timeIntervalSince1970: savedBackgroundDate)
                let timeInterval = Date().timeIntervalSince(savedDate)
                elapsedTime += timeInterval
                savedElapsedTime = elapsedTime
            }
        }
    }
    
    private func startTimer() {
        isRunning = true
        savedIsRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            savedElapsedTime = elapsedTime
        }
    }
    
    private func stopTimer() {
        isRunning = false
        savedIsRunning = false
        timer?.invalidate()
        timer = nil
        backgroundDate = nil
        savedBackgroundDate = 0
    }
    
    private func resetTimer() {
        stopTimer()
        elapsedTime = 0
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func stageString(from timeInterval: TimeInterval) -> String {
        switch timeStage(from: timeInterval) {
        case .anabolic:
            return "Anabolic"
        case .catabolic:
            return "Catabolic"
        default:
            return "Fat Burning"
        }
    }
    
    private func stageImage(from timeInterval: TimeInterval) -> String {
        switch timeStage(from: timeInterval) {
        case .anabolic:
            return "wrench.fill"
        case .catabolic:
            return "bolt.fill"
        default:
            return "flame.fill"
        }
    }
    
    private func stageColor(from timeInterval: TimeInterval) -> Color {
        switch timeStage(from: timeInterval) {
        case .anabolic:
            return .yellow
        case .catabolic:
            return .orange
        default:
            return .red
        }
    }
    
    private func stageDescription(from timeInterval: TimeInterval) -> String {
        switch timeStage(from: timeInterval) {
        case .anabolic:
            return """
                - Период активного пищеварения и усвоения питательных веществ
                - В крови повышен уровень глюкозы и инсулина
                - Организм запасает энергию в мышцах и печени в виде гликогена
                - Излишки углеводов преобразуются в жиры
                - Активно идут процессы восстановления и роста тканей
                - Это оптимальное время для тренировок на массу
                """
        case .catabolic:
            return """
                - Период разрушения тканей и уменьшения запасов энергии
                - В крови повышается уровень гормонов стресса (кортизол, адреналин)
                - Организм начинает расщеплять жиры и белки для получения энергии
                - Уровень глюкозы в крови снижается
                - Это оптимальное время для тренировок на снижение веса
                """
        default:
            return """
                - Период активного сжигания жиров
                - В крови повышается уровень гормона роста
                - Организм использует жиры в качестве основного источника энергии
                - Уровень глюкозы в крови снижается
                - Это оптимальное время для кардио-тренировок
                """
        }
    }
    
    private func stageExtraDescription(from timeInterval: TimeInterval) -> String? {
        switch timeStage(from: timeInterval) {
        case .fatBurning12:
            return """
                    12 часов: полное истощение запасов гликогена
                    """
        case .fatBurning16:
            return """
                    16-18 часов: максимальное жиросжигание
                    """
        case .fatBurning24:
            return """
                    24 часа: значительное усиление аутофагии
                    """
        case .fatBurning36:
            return """
                    36-48 часов: обновление иммунной системы
                    """
        default:
            return nil
        }
    }
    
    private func timeStage(from timeInterval: TimeInterval) -> TimeStage {
        let hours = Int(timeInterval) / 3600
        switch hours {
        case 0..<4:
            return .anabolic
        case 4..<8:
            return .catabolic
        case 8..<12:
            return .fatBurning8
        case 12..<16:
            return .fatBurning12
        case 16..<24:
            return .fatBurning16
        case 24..<36:
            return .fatBurning24
        default:
            return .fatBurning36
        }
    }
}


enum TimeStage {
    case anabolic
    case catabolic
    case fatBurning8
    case fatBurning12
    case fatBurning16
    case fatBurning24
    case fatBurning36
}

#Preview {
    TimerView()
}
