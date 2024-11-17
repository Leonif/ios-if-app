import SwiftUI

struct TimerView: View {
    @AppStorage("elapsed_time") private var savedElapsedTime: Double = 0
    @AppStorage("is_running") private var savedIsRunning: Bool = false
    @AppStorage("background_date") private var savedBackgroundDate: Double = 0
    @AppStorage("start_date") private var savedStartDate: Double = 0
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var backgroundDate: Date?
    
    var body: some View {
        Spacer()
        ScrollView {
            Spacer()
            VStack(spacing: 20) {
                Spacer()
                HStack {
                    Button(action: {
                        elapsedTime -= 10.minTimeInterval
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    VStack {
                        Text(getStartDateAndTime())
                        Text(elapsedTime.timeString)
                            .font(.system(size: 50))
                            .monospacedDigit()
                    }
                    
                    
                    
                    Button(action: {
                        elapsedTime += 10.minTimeInterval
                    }) {
                        Image(systemName: "arrow.right")
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
                
                HStack {
                    Text(stageString(from: elapsedTime))
                        .font(.system(size: 20))
                        .monospacedDigit()
                    
                    Image(systemName: stageImage(from: elapsedTime))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(stageColor(from: elapsedTime))
                        .frame(width: 20, height: 20)
                    
                    if timeStage(from: elapsedTime).startHour != 0 {
                        Text(timeStageString(from: elapsedTime))
                            .font(.system(size: 20))
                            .monospacedDigit()
                    }
                }
                
                buttonsView()
                
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
        }
        .onAppear {
            setupNotifications()
            restoreState()
        }
    }
    
    private func getStartDateAndTime() -> String {
        // Получаем дату начала
        let currentDate = Date()
        let startDate = currentDate.addingTimeInterval(-elapsedTime)
        
        // Форматируем дату
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        // Если нужна локализация для русского языка
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        return dateFormatter.string(from: startDate)
    }
    
    @ViewBuilder
    private func buttonsView() -> some View {
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
        
        HStack(spacing: 8) {
            Button(action: {
                stopTimer()
            }) {
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
                
                Text("Стоп")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(!isRunning ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }.padding(.horizontal)
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
        
        // возвращение на экран
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
        savedStartDate = Date().timeIntervalSince1970
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
                🍽️ Период активного пищеварения и усвоения питательных веществ
                🩸 В крови повышен уровень глюкозы и инсулина
                ⚡ Организм запасает энергию в мышцах и печени в виде гликогена
                🏋️ Излишки углеводов преобразуются в жиры
                🔄 Активно идут процессы восстановления и роста тканей
                💪 Это оптимальное время для тренировок на массу
                """
        case .catabolic:
            return """
                📉 Уровень глюкозы и инсулина снижается
                🔋 Организм начинает использовать запасы гликогена
                ⚖️ Активизируются процессы расщепления
                🧪 Начинается выработка глюкагона - гормона, способствующего расщеплению гликогена
                🔄 Организм постепенно переходит на использование жировых запасов
                🏃 В этой фазе хорошо проводить кардио тренировки
                """
        default:
            return """
                📪 Запасы гликогена истощаются
                🔥 Организм переключается на использование жировых запасов как основного источника энергии
                ⚗️ Активно вырабатываются кетоновые тела
                📉 Снижается уровень инсулина до минимума
                🧹 Активируются процессы аутофагии (очищение клеток)
                📈 Увеличивается выработка гормона роста
                ✨ Улучшается чувствительность к инсулину
                🔥 Происходит активное жиросжигание
                💪 Это оптимальное время для жиросжигающих тренировок
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
            return .anabolic// hours
        case 4..<8:
            return .catabolic // timeInterval - 4 * 3600
        case 8..<12:
            return .fatBurning8  // hours - 8
        case 12..<16:
            return .fatBurning12  // hours - 12
        case 16..<24:
            return .fatBurning16  // hours - 16
        case 24..<36:
            return .fatBurning24  // hours - 24
        default:
            return .fatBurning36  // hours - 36
        }
    }
    
    private func timeStageString(from timeInterval: TimeInterval) -> String {
        let stage = timeStage(from: timeInterval)
        let interval = timeInterval - TimeInterval(stage.startHour * 3600)
        return interval.timeString
    }
}




extension Int {
    var minTimeInterval: TimeInterval {
        TimeInterval(self * 60)
    }
}
