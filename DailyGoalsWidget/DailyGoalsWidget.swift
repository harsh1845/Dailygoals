import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date(), goals: []) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date(), goals: GoalDataManager.loadGoals()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), goals: GoalDataManager.loadGoals())
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let goals: [Goal]
}

// MARK: - 2. Redesigned Widget View
struct DailyGoalsWidgetEntryView : View {
    var entry: SimpleEntry

    // Sort: Incomplete first, then by color
    var sortedGoals: [Goal] {
        entry.goals.sorted { a, b in
            let aComplete = isCompleted(a)
            let bComplete = isCompleted(b)
            if aComplete == bComplete { return a.colorID < b.colorID }
            return !aComplete && bComplete
        }
    }
    
    func isCompleted(_ goal: Goal) -> Bool {
        guard Calendar.current.isDateInToday(goal.lastResetDate) else { return false }
        return goal.type == .time ? (goal.secondsCompletedToday >= goal.dailyQuotaSeconds) : (goal.currentCount >= goal.targetCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                Text("TODAY'S FOCUS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1) // Letter spacing
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(entry.date, format: .dateTime.weekday().day())
                    .font(.caption2.bold())
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3)) // Darker header bg
            
            // LIST
            if entry.goals.isEmpty {
                Spacer()
                Text("No goals set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                VStack(spacing: 1) { // Tight spacing with separators
                    ForEach(sortedGoals.prefix(4)) { goal in
                        GoalRow(goal: goal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        
                        // Separator Line
                        if goal.id != sortedGoals.prefix(4).last?.id {
                            Divider().background(Color.white.opacity(0.1))
                        }
                    }
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .containerBackground(for: .widget) {
            Color(red: 0.10, green: 0.10, blue: 0.12)
        }
    }
}

// MARK: - Subview: The Ring Row
struct GoalRow: View {
    let goal: Goal
    
    var isCurrentDay: Bool { Calendar.current.isDateInToday(goal.lastResetDate) }
    var currentVal: Int { isCurrentDay ? (goal.type == .time ? goal.secondsCompletedToday : goal.currentCount) : 0 }
    var targetVal: Int { goal.type == .time ? goal.dailyQuotaSeconds : goal.targetCount }
    
    var progress: Double {
        guard targetVal > 0 else { return 0 }
        return min(Double(currentVal) / Double(targetVal), 1.0)
    }
    
    // Use the safe color we just made
    var themeColor: Color {
        GoalColors.safeColor(for: goal.colorID)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 1. Progress Indicator (Left)
            ZStack {
                // Background ring - made slightly brighter
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(themeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 20, height: 20)

            // 2. Text Info
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if goal.type == .time {
                    let remaining = max(0, targetVal - currentVal)
                    Text(remaining == 0 ? "Done" : "\(formatTime(remaining)) left")
                        .font(.caption2)
                        // Make text theme-colored to match the ring
                        .foregroundStyle(themeColor.opacity(0.9))
                } else {
                    Text("\(currentVal)/\(targetVal)")
                        .font(.caption2)
                        .foregroundStyle(themeColor.opacity(0.9))
                }
            }
            Spacer()
            
            // 3. Action Button (Right) - Cleaner Look
            if goal.type == .time {
                Button(intent: ToggleGoalIntent(goal: goal)) {
                    ZStack {
                        // Remove the background circle for a cleaner look
                        // OR use a very subtle glow
                        Circle().fill(themeColor.opacity(0.15))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: goal.isActiveTimer ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(themeColor)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: IncrementGoalIntent(goal: goal)) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.1))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - 3. Configuration
struct DailyGoalsWidget: Widget {
    let kind: String = "DailyGoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyGoalsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Focus")
        .description("Track goals from your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
// MARK: - 4. Live Activity (iOS Only) - KEPT AS IS
#if os(iOS)
import ActivityKit

struct GoalActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoalTimerAttributes.self) { context in
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(GoalColors.all[context.state.colorID].opacity(0.3)).frame(width: 40, height: 40)
                    Circle().fill(GoalColors.all[context.state.colorID]).frame(width: 24, height: 24)
                    Image(systemName: "timer").font(.caption2.bold()).foregroundStyle(.black.opacity(0.7))
                }
                VStack(alignment: .leading) {
                    Text("Current Focus").font(.caption2).foregroundStyle(.secondary)
                    Text(context.state.goalName).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
                Text(context.state.startTime, style: .timer)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(GoalColors.all[context.state.colorID])
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.12))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Circle().fill(GoalColors.all[context.state.colorID]).frame(width: 20, height: 20)
                        Text("Focus").font(.caption).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundStyle(GoalColors.all[context.state.colorID])
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.goalName).font(.headline).foregroundStyle(.white).multilineTextAlignment(.center)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(GoalColors.all[context.state.colorID])
            } compactTrailing: {
                Text(context.state.startTime, style: .timer).frame(width: 40).foregroundStyle(GoalColors.all[context.state.colorID]).font(.system(size: 12))
            } minimal: {
                Image(systemName: "timer").foregroundStyle(GoalColors.all[context.state.colorID])
            }
        }
    }
}
#endif

// MARK: - 5. Bundle
@main
struct DailyGoalsWidgets: WidgetBundle {
    var body: some Widget {
        DailyGoalsWidget()
        #if os(iOS)
        GoalActivityWidget()
        #endif
    }
}

// Extension for safe styling
extension View {
    func safeWidgetBackground() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            return containerBackground(Color(red: 0.10, green: 0.10, blue: 0.12), for: .widget)
        } else {
            return background(Color(red: 0.10, green: 0.10, blue: 0.12))
        }
    }
}
