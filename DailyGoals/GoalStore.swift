import Foundation
import Combine
import SwiftUI
import WidgetKit

#if os(iOS)
import ActivityKit
#endif

// Define Attributes for iOS only
#if os(iOS)
struct GoalTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var goalID: UUID
        var goalName: String
        var startTime: Date
        var colorID: Int
    }
}
#endif

final class GoalStore: ObservableObject {
    // 1. REMOVED 'didSet'. This stops the overwrite loop.
    @Published var goals: [Goal] = []
    
    #if os(iOS)
    private var currentActivity: Activity<GoalTimerAttributes>?
    #endif
    
    init() {
        refresh()
    }

    func refresh() {
        self.goals = GoalDataManager.loadGoals()
        self.checkDayChanges()
        if isMainApp {
            Task {
                await NotificationManager.syncNotifications(for: self.goals)
            }
        }
    }

    // MARK: - Manual Save Helper
    private var isMainApp: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSExtension") == nil
    }

    private func save() {
        Task {
            GoalDataManager.saveGoals(self.goals)
            if isMainApp {
                await NotificationManager.syncNotifications(for: self.goals)
            }
        }
    }

    func updateGoal(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx] = goal
        save()
    }

    // MARK: - Public API
    
    func addGoal(name: String, type: GoalType, targetValue: Int, scheduleType: ScheduleType, specificDays: [Int]?, reminderEnabled: Bool = false, reminderHour: Int? = nil, reminderMinute: Int? = nil) {
        let totalSeconds = type == .time ? targetValue : 0
        guard (type == .time && totalSeconds > 0) || (type == .count && targetValue > 0) else { return }
        
        let now = Date()
        let today = startOfDay(now)
        
        var schedule = GoalSchedule.everyDay
        schedule.type = scheduleType
        switch scheduleType {
        case .everyDay: break
        case .alternateDays: schedule.alternateStartDate = today
        case .specificDays: schedule.specificDays = specificDays?.sorted()
        }
        
        let goal = Goal(
            name: name,
            type: type,
            dailyQuotaSeconds: type == .time ? targetValue : 0,
            secondsCompletedToday: 0,
            targetCount: type == .count ? targetValue : 1,
            currentCount: 0,
            lastResetDate: today,
            schedule: schedule,
            createdDate: now,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        goals.append(goal)
        save() // <--- Manual Save
    }
    
    func deleteGoal(_ goal: Goal) {
        if isMainApp {
            NotificationManager.cancelReminder(for: goal.id)
        }
        goals.removeAll { $0.id == goal.id }
        save() // <--- Manual Save
    }
    
    func startTimer(for goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }), goal.type == .time else { return }
        
        var g = goals[idx]
        let now = Date()
        let today = startOfDay(now)
        
        if startOfDay(g.lastResetDate) < today {
            processDayChange(index: idx, todayStart: today)
            g = goals[idx]
        }
        
        if g.isActiveTimer { return }
        
        g.isActiveTimer = true
        g.timerStartTimestamp = Date()
        goals[idx] = g
        save() // <--- Manual Save
        
        #if os(iOS)
        startLiveActivity(for: g)
        #endif
    }
    
    func pauseTimer(for goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }),
              goals[idx].isActiveTimer,
              let start = goals[idx].timerStartTimestamp else { return }
        
        let elapsed = Int(Date().timeIntervalSince(start))
        goals[idx].secondsCompletedToday += max(0, elapsed)
        goals[idx].isActiveTimer = false
        goals[idx].timerStartTimestamp = nil
        
        if goals[idx].secondsCompletedToday >= goals[idx].dailyQuotaSeconds {
            maybeGrantReward(index: idx)
        }
        
        goals[idx] = goals[idx] // Update published property
        save() // <--- Manual Save
        
        #if os(iOS)
        endLiveActivity()
        #endif
    }
    
    func incrementCount(for goal: Goal, by amount: Int) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        
        var g = goals[idx]
        let now = Date()
        let today = startOfDay(now)
        
        if startOfDay(g.lastResetDate) < today {
            processDayChange(index: idx, todayStart: today)
            g = goals[idx]
        }
        
        if g.type == .count {
            g.currentCount = max(0, g.currentCount + amount)
            
            if g.currentCount >= g.targetCount && !g.hasEarnedRewardToday {
                g.rewardPoints += 10
                g.streak += 1
                g.hasEarnedRewardToday = true
            }
        }
        
        goals[idx] = g
        save() // <--- Manual Save
    }
    
    func displayedSeconds(for goal: Goal) -> Int {
        guard goal.type == .time else { return 0 }
        
        if goal.isActiveTimer, let start = goal.timerStartTimestamp {
            let elapsed = Int(Date().timeIntervalSince(start))
            return goal.secondsCompletedToday + max(elapsed, 0)
        } else {
            return goal.secondsCompletedToday
        }
    }
    
    func tick() {
        // 1. Sync check
        // This READS from disk. Since we removed didSet, this will NOT trigger a write.
        // This is the key fix.
        let loadedGoals = GoalDataManager.loadGoals()
        if loadedGoals != self.goals {
            self.goals = loadedGoals
        }
        
        // 2. Timer Logic
        if goals.contains(where: { $0.isActiveTimer }) {
            objectWillChange.send()
        }
        
        // 3. Reset Check
        checkDayChanges()
    }
    
    // NEW: Centralized Day Change Checker
    private func checkDayChanges() {
        let now = Date()
        let todayStart = Calendar.current.startOfDay(for: now)
        
        var changed = false
        for idx in goals.indices {
            if Calendar.current.startOfDay(for: goals[idx].lastResetDate) < todayStart {
                // processDayChange saves internally now, but let's be safe
                processDayChange(index: idx, todayStart: todayStart)
                changed = true
            }
        }
        if changed { save() }
    }

    func summary() -> (percentage: Double, progressLabel: String) {
        var totalProgress: Double = 0
        let count = Double(goals.count)
        guard count > 0 else { return (0, "0/0") }
        
        var completedGoals = 0
        for g in goals {
            if g.type == .time {
                let active = displayedSeconds(for: g)
                let target = max(1, g.dailyQuotaSeconds)
                let p = Double(active) / Double(target)
                totalProgress += p
                if active >= target { completedGoals += 1 }
            } else {
                let p = Double(g.currentCount) / Double(g.targetCount)
                totalProgress += p
                if g.currentCount >= g.targetCount { completedGoals += 1 }
            }
        }
        
        let overallPercent = totalProgress / count
        return (overallPercent, "\(completedGoals)/\(Int(count)) goals")
    }
    
    // MARK: - iOS Live Activity Helpers
    #if os(iOS)
    private func startLiveActivity(for goal: Goal) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = GoalTimerAttributes()
        let state = GoalTimerAttributes.ContentState(
            goalID: goal.id,
            goalName: goal.name,
            startTime: Date(),
            colorID: goal.colorID
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    private func endLiveActivity() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    #endif

    // MARK: - Private helpers
    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private func processDayChange(index: Int, todayStart: Date) {
        var g = goals[index]
        
        if g.type == .time, g.isActiveTimer, let start = g.timerStartTimestamp {
            let elapsed = Int(todayStart.timeIntervalSince(start))
            g.secondsCompletedToday = min(
                g.dailyQuotaSeconds,
                g.secondsCompletedToday + max(0, elapsed)
            )
            g.isActiveTimer = false
            g.timerStartTimestamp = nil
        }
        
        // Save History
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: g.lastResetDate)
        
        let val = (g.type == .time) ? g.secondsCompletedToday : g.currentCount
        if val > 0 { g.history[dateKey] = val }

        let completedYesterday: Bool
        if g.type == .time {
            completedYesterday = g.secondsCompletedToday >= g.dailyQuotaSeconds
        } else {
            completedYesterday = g.currentCount >= g.targetCount
        }
        
        if completedYesterday {
            if !g.hasEarnedRewardToday {
                g.rewardPoints += 10
                g.streak += 1
                g.hasEarnedRewardToday = true
            }
        } else {
            g.rewardPoints = max(0, g.rewardPoints - 10)
            g.streak = 0
        }
        
        g.secondsCompletedToday = 0
        g.currentCount = 0
        g.lastResetDate = todayStart
        g.hasEarnedRewardToday = false
        
        goals[index] = g
        // Note: No save() call here, caller handles it to batch updates
    }
    
    private func maybeGrantReward(index: Int) {
        var g = goals[index]
        let total = displayedSeconds(for: g)
        
        guard total >= g.dailyQuotaSeconds, !g.hasEarnedRewardToday else { return }
        
        let reward = max(1, g.dailyQuotaSeconds / 60)
        g.rewardPoints += reward
        g.streak += 1
        g.hasEarnedRewardToday = true
        
        goals[index] = g
        save() // <--- Manual Save
    }
}
