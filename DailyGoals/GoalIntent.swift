//
//  ToggleGoalIntent.swift
//  DailyGoals
//
//  Created by harsh selarka on 30/11/2025.
//


import AppIntents
import SwiftUI

struct ToggleGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Goal Timer"
    
    @Parameter(title: "Goal ID")
    var goalID: String
    
    init() {}
    
    init(goal: Goal) {
        self.goalID = goal.id.uuidString
    }
    
    func perform() async throws -> some IntentResult {
        // Instantiate store (it will load from the shared App Group)
        let store = GoalStore()
        
        if let goal = store.goals.first(where: { $0.id.uuidString == goalID }) {
            if goal.isActiveTimer {
                store.pauseTimer(for: goal)
            } else {
                store.startTimer(for: goal)
            }
        }
        return .result()
    }
}