import Foundation

// MARK: - Schedule & Type (Keep existing enums)
enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case everyDay, alternateDays, specificDays
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .everyDay: return "Every day"
        case .alternateDays: return "Alternate days"
        case .specificDays: return "Specific days"
        }
    }
}

struct GoalSchedule: Codable, Equatable {
    var type: ScheduleType
    var specificDays: [Int]?
    var alternateStartDate: Date?
    static var everyDay: GoalSchedule { GoalSchedule(type: .everyDay, specificDays: nil, alternateStartDate: nil) }
}

enum GoalType: String, Codable, CaseIterable {
    case time, count
}

// MARK: - Goal Struct
struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: GoalType = .time

    var dailyQuotaSeconds: Int
    var secondsCompletedToday: Int = 0

    var targetCount: Int = 1
    var currentCount: Int = 0

    var lastResetDate: Date = Calendar.current.startOfDay(for: Date())
    var rewardPoints: Int = 0
    var streak: Int = 0
    
    // FIX: Make history optional for decoding, but give it a default value
    var history: [String: Int] = [:]

    var isActiveTimer: Bool = false
    var timerStartTimestamp: Date? = nil
    var hasEarnedRewardToday: Bool = false
    var schedule: GoalSchedule = .everyDay
    var createdDate: Date = Date()
    var colorID: Int = Int.random(in: 0..<GoalColors.all.count)

    var reminderEnabled: Bool = false
    var reminderHour: Int? = nil
    var reminderMinute: Int? = nil
    
    // --- MANUAL DECODING TO FIX CRASH ---
    // This allows the app to read old files that are missing the "history" key
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(GoalType.self, forKey: .type)
        dailyQuotaSeconds = try container.decode(Int.self, forKey: .dailyQuotaSeconds)
        secondsCompletedToday = try container.decode(Int.self, forKey: .secondsCompletedToday)
        targetCount = try container.decode(Int.self, forKey: .targetCount)
        currentCount = try container.decode(Int.self, forKey: .currentCount)
        lastResetDate = try container.decode(Date.self, forKey: .lastResetDate)
        rewardPoints = try container.decode(Int.self, forKey: .rewardPoints)
        streak = try container.decode(Int.self, forKey: .streak)
        
        // THE FIX: Use decodeIfPresent. If "history" is missing, use [:]
        history = try container.decodeIfPresent([String: Int].self, forKey: .history) ?? [:]
        
        isActiveTimer = try container.decode(Bool.self, forKey: .isActiveTimer)
        timerStartTimestamp = try container.decodeIfPresent(Date.self, forKey: .timerStartTimestamp)
        hasEarnedRewardToday = try container.decode(Bool.self, forKey: .hasEarnedRewardToday)
        schedule = try container.decode(GoalSchedule.self, forKey: .schedule)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        colorID = try container.decode(Int.self, forKey: .colorID)
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour)
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute)
    }
    
    // Need to explicitly declare memberwise init because we added a custom init(from:)
    init(id: UUID = UUID(), name: String, type: GoalType, dailyQuotaSeconds: Int, secondsCompletedToday: Int, targetCount: Int, currentCount: Int, lastResetDate: Date, rewardPoints: Int = 0, streak: Int = 0, history: [String : Int] = [:], isActiveTimer: Bool = false, timerStartTimestamp: Date? = nil, hasEarnedRewardToday: Bool = false, schedule: GoalSchedule, createdDate: Date, colorID: Int = Int.random(in: 0..<GoalColors.all.count), reminderEnabled: Bool = false, reminderHour: Int? = nil, reminderMinute: Int? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.dailyQuotaSeconds = dailyQuotaSeconds
        self.secondsCompletedToday = secondsCompletedToday
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.lastResetDate = lastResetDate
        self.rewardPoints = rewardPoints
        self.streak = streak
        self.history = history
        self.isActiveTimer = isActiveTimer
        self.timerStartTimestamp = timerStartTimestamp
        self.hasEarnedRewardToday = hasEarnedRewardToday
        self.schedule = schedule
        self.createdDate = createdDate
        self.colorID = colorID
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    var reminderDate: Date {
        get {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = reminderHour ?? 9
            components.minute = reminderMinute ?? 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour
            reminderMinute = components.minute
        }
    }
}

extension UUID: Identifiable {
    public var id: UUID { self }
}
