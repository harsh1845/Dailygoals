import AppIntents
import WidgetKit
import Foundation

// MARK: - 1. Toggle Timer Intent
struct ToggleGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Goal Timer"
    
    @Parameter(title: "Goal ID")
    var goalID: String
    
    init() {}
    
    init(goal: Goal) {
        self.goalID = goal.id.uuidString
    }
    
    func perform() async throws -> some IntentResult {
        // 1. Load from the SHARED Local Storage
        var goals = GoalDataManager.loadGoals()
        
        // 2. Find and update
        if let index = goals.firstIndex(where: { $0.id.uuidString == goalID }) {
            var goal = goals[index]
            
            if goal.isActiveTimer {
                // PAUSE
                if let start = goal.timerStartTimestamp {
                    let elapsed = Int(Date().timeIntervalSince(start))
                    goal.secondsCompletedToday += max(0, elapsed)
                }
                goal.isActiveTimer = false
                goal.timerStartTimestamp = nil
            } else {
                // START
                goal.isActiveTimer = true
                goal.timerStartTimestamp = Date()
            }
            
            goals[index] = goal
            
            // 3. Save back to Local Storage
            GoalDataManager.saveGoals(goals)
            
            // 4. Force Widget Refresh
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
}

// MARK: - 2. Increment Counter Intent
struct IncrementGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Goal"
    
    @Parameter(title: "Goal ID")
    var goalID: String
    
    init() {}
    
    init(goal: Goal) {
        self.goalID = goal.id.uuidString
    }
    
    func perform() async throws -> some IntentResult {
        var goals = GoalDataManager.loadGoals()
        
        if let index = goals.firstIndex(where: { $0.id.uuidString == goalID }) {
            var goal = goals[index]
            goal.currentCount += 1
            
            // Basic Streak Logic (Simplified for Widget)
            if goal.currentCount >= goal.targetCount && !goal.hasEarnedRewardToday {
                goal.rewardPoints += 10
                goal.streak += 1
                goal.hasEarnedRewardToday = true
            }
            
            goals[index] = goal
            GoalDataManager.saveGoals(goals)
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}
