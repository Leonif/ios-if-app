//
//  TimerViewModel.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI
import Combine

final class TimerViewModel: ObservableObject {
    @AppStorage("elapsed_time") private var savedElapsedTime: Double = 0
    @AppStorage("is_running") private var savedIsRunning: Bool = false
    @AppStorage("background_date") private var savedBackgroundDate: Double = 0
    @AppStorage("start_date") private var savedStartDate: Double = 0
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    
    private var timer: Timer?
    private var backgroundDate: Date?
    
    var elapsedTimeString: String {
        elapsedTime.timeString
    }
    
    var startDateTimeString: String {
        let currentDate = Date()
        let startDate = currentDate.addingTimeInterval(-elapsedTime)
        
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
            backgroundDate = Date()
            savedBackgroundDate = backgroundDate?.timeIntervalSince1970 ?? 0
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func handleForegroundTransition() {
        if isRunning {
            let savedDate = Date(timeIntervalSince1970: savedBackgroundDate)
            let timeInterval = Date().timeIntervalSince(savedDate)
            elapsedTime += timeInterval
            savedElapsedTime = elapsedTime
            startTimer()
        }
    }
    
    private func restoreState() {
        elapsedTime = savedElapsedTime
        isRunning = savedIsRunning
        
        if isRunning, savedBackgroundDate > 0 {
            let savedDate = Date(timeIntervalSince1970: savedBackgroundDate)
            let timeInterval = Date().timeIntervalSince(savedDate)
            elapsedTime += timeInterval
            savedElapsedTime = elapsedTime
        }
    }
    
    func startTimer() {
        isRunning = true
        savedIsRunning = true
        savedStartDate = Date().timeIntervalSince1970
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
            self?.savedElapsedTime = self?.elapsedTime ?? 0
        }
    }
    
    func stopTimer() {
        isRunning = false
        savedIsRunning = false
        timer?.invalidate()
        timer = nil
        backgroundDate = nil
        savedBackgroundDate = 0
    }
    
    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        savedElapsedTime = 0
    }
    
    func adjustTime(by interval: TimeInterval) {
        elapsedTime += interval
        savedElapsedTime = elapsedTime
    }
}
