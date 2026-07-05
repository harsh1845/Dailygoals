//
//  GoalColors.swift
//  DailyGoals
//
//  Created by harsh selarka on 22/11/2025.
//


import SwiftUI

struct GoalColors {
    static let all: [Color] = [
        Color(red: 0.95, green: 0.78, blue: 0.98), // lilac
        Color(red: 0.80, green: 0.87, blue: 1.00), // baby blue
        Color(red: 0.80, green: 1.00, blue: 0.90), // mint
        Color(red: 1.00, green: 0.90, blue: 0.75), // peach
        Color(red: 1.00, green: 0.80, blue: 0.85), // rose
        Color(red: 0.90, green: 0.90, blue: 1.00), // soft lavender
        Color(red: 1.00, green: 0.95, blue: 0.70), // pale yellow
        Color(red: 0.75, green: 0.95, blue: 1.00)  // sky teal
    ]
    
    // NEW: Safe helper that never crashes or returns grey
    static func safeColor(for id: Int) -> Color {
        if id >= 0 && id < all.count {
            return all[id]
        }
        return .cyan // <--- The "Pretty" Fallback (instead of grey)
    }
}
