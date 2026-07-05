import Foundation
import UserNotifications

enum NotificationManager {
    private static let center = UNUserNotificationCenter.current()

    static func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    static func syncNotifications(for goals: [Goal]) async {
        let pending = await center.pendingNotificationRequests()
        let goalIDs = Set(goals.map(\.id.uuidString))

        for request in pending where request.identifier.hasPrefix("goal-") {
            let id = String(request.identifier.dropFirst("goal-".count))
            if !goalIDs.contains(id) {
                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
        }

        for goal in goals where goal.reminderEnabled {
            await scheduleReminder(for: goal)
        }
    }

    static func scheduleReminder(for goal: Goal) async {
        let identifier = notificationID(for: goal.id)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard goal.reminderEnabled,
              let hour = goal.reminderHour,
              let minute = goal.reminderMinute else { return }

        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Reminder"
        content.body = goal.name
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification for \(goal.name): \(error)")
        }
    }

    static func cancelReminder(for goalID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID(for: goalID)])
    }

    private static func notificationID(for goalID: UUID) -> String {
        "goal-\(goalID.uuidString)"
    }
}
