//
//  TimerViewModel.swift
//  IFApp
//
//  Created by LEONID NIFANTIJEV on 17.11.2024.
//

import SwiftUI
import Combine
import StoreKit
import UIKit

final class TimerViewModel: ObservableObject {
    // Сохраняем только самые необходимые значения
    @AppStorage("start_timestamp") private var savedStartTimestamp: Double = 0
    @AppStorage("is_running") private var savedIsRunning: Bool = false
    // Сколько реальных сессий голодания человек довёл до конца - для запроса оценки
    @AppStorage("completed_sessions_count") private var completedSessionsCount: Int = 0

    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false

    // Засчитываем сессию как завершённую, только если дошли до жиросжигания (8 ч) -
    // это отсекает случайные старт/стоп. Оценку просим после порога завершённых сессий.
    private let minSessionDurationForReview: TimeInterval = 8 * 3600
    private let completedSessionsThreshold = 2
    private var didRequestReviewThisLaunch = false

    private var timer: Timer?
    
    var elapsedTimeString: String {
        elapsedTime.timeString
    }
    
    var startDateTimeString: String? {
        guard savedStartTimestamp > 0 else { return nil }
        let startDate = Date(timeIntervalSince1970: savedStartTimestamp)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        dateFormatter.locale = Locale.current
        
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
        let finishedDuration = elapsedTime
        clearRunningState()
        maybeRequestReview(forCompletedSession: finishedDuration)
    }

    func resetTimer() {
        // Сброс - это не завершение сессии, оценку тут не просим
        clearRunningState()
        elapsedTime = 0
    }

    private func clearRunningState() {
        isRunning = false
        savedIsRunning = false
        timer?.invalidate()
        timer = nil
        savedStartTimestamp = 0
    }

    private func maybeRequestReview(forCompletedSession duration: TimeInterval) {
        // Только реальная завершённая сессия, не случайный старт/стоп
        guard duration >= minSessionDurationForReview else { return }
        completedSessionsCount += 1

        // Не на launch, не чаще раза за запуск приложения и только после порога.
        // Частоту показов (лимит Apple) дальше регулирует сама система.
        guard !didRequestReviewThisLaunch,
              completedSessionsCount >= completedSessionsThreshold else { return }
        didRequestReviewThisLaunch = true

        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes.first(where: {
                $0.activationState == .foregroundActive
            }) as? UIWindowScene else {
                return
            }
            AppStore.requestReview(in: scene)
        }
    }
    
    func adjustTime(by interval: TimeInterval) {
        elapsedTime = max(0, elapsedTime + interval)
        if isRunning {
            // При корректировке времени обновляем сохраненное время старта
            savedStartTimestamp = Date().timeIntervalSince1970 - elapsedTime
        }
    }
}
