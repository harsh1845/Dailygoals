import Foundation
import WidgetKit

struct GoalDataManager {
    static let suiteName = "group.com.harsh.DailyGoals"
    static let storageKey = "DailyGoalsStorage"
    static let sharedFileName = "goals.json"

    /// Whether the App Group container is available (required for widget data sharing).
    static var isAppGroupAvailable: Bool {
        sharedContainerURL != nil
    }

    private static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    private static var sharedFileURL: URL? {
        sharedContainerURL?.appendingPathComponent(sharedFileName)
    }

    /// Loads goals from the shared App Group container, migrating legacy data if needed.
    static func loadGoals() -> [Goal] {
        // 1. Shared JSON file (most reliable for widget extensions)
        if let goals = loadFromSharedFile(), !goals.isEmpty {
            return goals
        }

        // 2. App Group UserDefaults
        if let shared = UserDefaults(suiteName: suiteName),
           let goals = decodeGoals(from: shared), !goals.isEmpty {
            writeToSharedFile(goals)
            return goals
        }

        // 3. Main-app-only fallback — migrate into App Group when possible
        if let goals = decodeGoals(from: .standard), !goals.isEmpty {
            persistToSharedStorage(goals)
            return goals
        }

        return []
    }

    /// Saves goals to the shared App Group container and refreshes widgets.
    static func saveGoals(_ goals: [Goal]) {
        do {
            let data = try JSONEncoder().encode(goals)
            persistToSharedStorage(goals, data: data)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error saving local goals: \(error)")
        }
    }

    /// Forces current goals into shared storage and reloads widget timelines.
    static func forceWidgetSync(_ goals: [Goal]) {
        saveGoals(goals)
    }

    // MARK: - Private

    private static func loadFromSharedFile() -> [Goal]? {
        guard let url = sharedFileURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return decodeGoals(from: data)
    }

    private static func writeToSharedFile(_ goals: [Goal]) {
        guard let url = sharedFileURL,
              let data = try? JSONEncoder().encode(goals) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func persistToSharedStorage(_ goals: [Goal], data: Data? = nil) {
        let encoded = data ?? (try? JSONEncoder().encode(goals))
        guard let encoded else { return }

        if sharedFileURL != nil {
            writeToSharedFile(goals)
        }

        if let shared = UserDefaults(suiteName: suiteName) {
            shared.set(encoded, forKey: storageKey)
        } else {
            print("DailyGoals: App Group unavailable — widget will not receive updates.")
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private static func decodeGoals(from defaults: UserDefaults) -> [Goal]? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return decodeGoals(from: data)
    }

    private static func decodeGoals(from data: Data) -> [Goal]? {
        do {
            return try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("Error decoding goals: \(error)")
            return nil
        }
    }
}
