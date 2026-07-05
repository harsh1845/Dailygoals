import Foundation
import WidgetKit

struct GoalDataManager {
    static let suiteName = "group.com.harsh.DailyGoals"
    static let storageKey = "DailyGoalsStorage"
    private static let legacyStorageKey = "DailyGoalsStorage"

    /// Whether the App Group container is available (required for widget data sharing).
    static var isAppGroupAvailable: Bool {
        UserDefaults(suiteName: suiteName) != nil
    }

    /// Loads goals from the shared App Group container, migrating legacy data if needed.
    static func loadGoals() -> [Goal] {
        if let shared = UserDefaults(suiteName: suiteName),
           let goals = decodeGoals(from: shared) {
            return goals
        }

        // Main app may have saved to standard UserDefaults before App Group was configured.
        if let goals = decodeGoals(from: .standard), !goals.isEmpty {
            if let shared = UserDefaults(suiteName: suiteName) {
                persist(goals, to: shared)
                UserDefaults.standard.removeObject(forKey: legacyStorageKey)
            }
            return goals
        }

        return []
    }

    /// Saves goals to the shared App Group container and refreshes widgets.
    static func saveGoals(_ goals: [Goal]) {
        do {
            let data = try JSONEncoder().encode(goals)

            if let shared = UserDefaults(suiteName: suiteName) {
                persist(data, to: shared)
            } else {
                // Widget cannot read this fallback — App Group must be enabled when sideloading.
                print("DailyGoals: App Group unavailable — widget will not receive updates.")
                UserDefaults.standard.set(data, forKey: legacyStorageKey)
            }

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error saving local goals: \(error)")
        }
    }

    private static func decodeGoals(from defaults: UserDefaults) -> [Goal]? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("Error decoding goals: \(error)")
            return nil
        }
    }

    private static func persist(_ goals: [Goal], to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(goals) else { return }
        persist(data, to: defaults)
    }

    private static func persist(_ data: Data, to defaults: UserDefaults) {
        defaults.set(data, forKey: storageKey)
    }
}
