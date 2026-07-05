import SwiftUI

@main
struct DailyGoalsApp: App {
    @StateObject private var store = GoalStore()
    @State private var activeGoal: UUID?
    
    // We don't need scenePhase anymore since local saving happens automatically in GoalStore
    
    var body: some Scene {
        WindowGroup {
            ContentView(activeGoal: $activeGoal)
                .environmentObject(store)
        }
    }
}
