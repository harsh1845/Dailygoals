import Foundation

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String

    /// Target time per day in seconds
    var dailyQuotaSeconds: Int

    /// How many seconds have been logged (saved) today
    var secondsCompletedToday: Int = 0

    /// The date (startOfDay) this progress belongs to
    var lastResetDate: Date = Calendar.current.startOfDay(for: Date())

    /// Total reward points (XP)
    var rewardPoints: Int = 0

    /// Consecutive days finished
    var streak: Int = 0

    /// Is the timer currently running?
    var isActiveTimer: Bool = false

    /// When the timer was last started (if running)
    var timerStartTimestamp: Date? = nil

    /// Did we already grant XP for completing *today*?
    var hasEarnedRewardToday: Bool = false
}
