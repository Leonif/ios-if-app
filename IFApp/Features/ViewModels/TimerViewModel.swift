//
//  TimerViewModel.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI
import Combine

final class TimerViewModel: ObservableObject {
    // Сохраняем только самые необходимые значения
    @AppStorage("start_timestamp") private var savedStartTimestamp: Double = 0
    @AppStorage("is_running") private var savedIsRunning: Bool = false
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    
    
    private var timer: Timer?
    
    var elapsedTimeString: String {
        elapsedTime.timeString
    }
    
    var startDateTimeString: String? {
        guard savedStartTimestamp > 0 else { return nil }
        let startDate = Date(timeIntervalSince1970: savedStartTimestamp)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        return dateFormatter.string(from: startDate)
    }
    
    var currentStageTimeString: String {
        let currentStage = TimeStage.determineStage(from: elapsedTime)
        let interval = elapsedTime - TimeInterval(currentStage.startHour * 3600)
        return interval.timeString
    }
    
    init() {
        restoreState()
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBackgroundTransition()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleForegroundTransition()
        }
    }
    
    private func handleBackgroundTransition() {
        if isRunning {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func handleForegroundTransition() {
        if isRunning {
            updateElapsedTime()
            startTimer()
        }
    }
    
    private func updateElapsedTime() {
        if savedStartTimestamp > 0 {
            elapsedTime = Date().timeIntervalSince1970 - savedStartTimestamp
        }
    }
    
    private func restoreState() {
        isRunning = savedIsRunning
        
        if isRunning {
            updateElapsedTime()
            startTimer()
        }
    }
    
    func startTimer() {
        isRunning = true
        savedIsRunning = true
        
        // Если таймер не был запущен ранее, сохраняем время старта
        if savedStartTimestamp == 0 {
            savedStartTimestamp = Date().timeIntervalSince1970 - elapsedTime
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    func stopTimer() {
        isRunning = false
        savedIsRunning = false
        timer?.invalidate()
        timer = nil
        savedStartTimestamp = 0
    }
    
    func resetTimer() {
        stopTimer()
        elapsedTime = 0
    }
    
    func adjustTime(by interval: TimeInterval) {
        elapsedTime += interval
        if isRunning {
            // При корректировке времени обновляем сохраненное время старта
            savedStartTimestamp = Date().timeIntervalSince1970 - elapsedTime
        }
    }
}
