import SwiftUI
import WidgetKit

@main
struct DailyGoalsApp: App {
    @StateObject private var store = GoalStore()
    @State private var activeGoal: UUID?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView(activeGoal: $activeGoal)
                .environmentObject(store)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.refresh()
                        GoalDataManager.forceWidgetSync(store.goals)
                    }
                }
        }
    }
}
