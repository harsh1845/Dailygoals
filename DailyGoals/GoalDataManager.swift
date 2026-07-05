//
//  is.swift
//  DailyGoals
//
//  Created by harsh selarka on 30/11/2025.
//


import Foundation
import WidgetKit

// This struct is SAFE to use in Widgets, Intents, and the App
struct GoalDataManager {
    // Make sure this matches your App Group exactly
    static let suiteName = "group.com.harshselarka.dailygoals.local" 
    static let storageKey = "DailyGoalsStorage"
    
    // 1. Load Goals (Safe for Background)
    static func loadGoals() -> [Goal] {
        let userDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        guard let data = userDefaults.data(forKey: storageKey) else { return [] }
        
        do {
            return try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            return []
        }
    }
    
    // 2. Save Goals (Safe for Background)
    static func saveGoals(_ goals: [Goal]) {
        do {
            let data = try JSONEncoder().encode(goals)
            if let userDefaults = UserDefaults(suiteName: suiteName) {
                userDefaults.set(data, forKey: storageKey)
            }
            // Tell Widgets to refresh
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error saving goals: \(error)")
        }
    }
}