import SwiftUI
import Charts // Requires iOS 16+

struct HistoryView: View {
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    HStack(spacing: 20) {
                        StatBox(title: "Streak", value: "\(goal.streak)", icon: "flame.fill", color: .orange)
                        StatBox(title: "XP", value: "\(goal.rewardPoints)", icon: "star.fill", color: .yellow)
                    }
                    .padding(.horizontal)

                    // The Chart
                    VStack(alignment: .leading) {
                        Text("Last 7 Days").font(.headline)
                        if goal.history.isEmpty {
                            Text("No history recorded yet.")
                                .foregroundStyle(.secondary)
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        } else {
                            Chart {
                                ForEach(getHistoryData(), id: \.date) { item in
                                    BarMark(
                                        x: .value("Date", item.date, unit: .day),
                                        y: .value("Amount", Double(item.value))
                                    )
                                    .foregroundStyle(GoalColors.all[goal.colorID])
                                    
                                    // Rule Mark for Target
                                    RuleMark(y: .value("Target", Double(goalTypeTarget)))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .background(AppBackground())
            .navigationTitle(goal.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var goalTypeTarget: Int {
        goal.type == .time ? goal.dailyQuotaSeconds : goal.targetCount
    }
    
    // Helper to sort and format history for the Chart
    private func getHistoryData() -> [(date: Date, value: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var result: [(Date, Int)] = []
        
        // Get last 7 days including today (even if empty)
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                let key = formatter.string(from: date)
                let val = goal.history[key] ?? 0
                result.append((date, val))
            }
        }
        return result.sorted { $0.0 < $1.0 }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}