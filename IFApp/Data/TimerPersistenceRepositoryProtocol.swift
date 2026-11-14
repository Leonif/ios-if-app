//
//  TimerPersistenceRepositoryProtocol.swift
//  IFApp
//

protocol TimerPersistenceRepositoryProtocol {
    func load() -> (fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, stagedElapsed: Double, fastEndTimestamp: Double, streakCount: Int, lastGoalDate: String?, freezeSpentMonth: String?)
    func save(fastStartTimestamp: Double, goalHours: Double, isRunning: Bool, completedSessions: Int, hasCelebrated: Bool, eatingStartTimestamp: Double, isEating: Bool, stagedElapsed: Double, fastEndTimestamp: Double, streakCount: Int, lastGoalDate: String?, freezeSpentMonth: String?)
    func loadPlanHours() -> Int?
    func savePlanHours(_ hours: Int)
    func loadLastMilestoneShown() -> Int
    func saveLastMilestoneShown(_ days: Int)
}
