import SwiftUI
import Charts

struct TaskHistoryView: View {
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground() // Aurora background
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Stats
                        HStack(spacing: 20) {
                            statBox(title: "Streak", value: "\(goal.streak)", icon: "flame.fill", color: .orange)
                            statBox(title: "XP", value: "\(goal.rewardPoints)", icon: "star.fill", color: .yellow)
                        }
                        .padding(.horizontal)

                        // The Chart
                        VStack(alignment: .leading) {
                            Text("Last 7 Days").font(.headline).foregroundStyle(.white)
                            
                            if goal.history.isEmpty {
                                Text("No history recorded yet.")
                                    .foregroundStyle(.secondary)
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart {
                                    ForEach(getHistoryData(), id: \.date) { item in
                                        BarMark(
                                            x: .value("Date", item.date, unit: .day),
                                            y: .value("Amount", Double(item.value))
                                        )
                                        .foregroundStyle(GoalColors.all[goal.colorID])
                                        .cornerRadius(4)
                                    }
                                    
                                    RuleMark(y: .value("Target", Double(goalTypeTarget)))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(height: 200)
                                .chartYAxis { AxisMarks(position: .leading) }
                                .chartXAxis { AxisMarks(values: .stride(by: .day)) }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func getHistoryData() -> [(date: Date, value: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var result: [(Date, Int)] = []
        
        // Last 7 days
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                let key = formatter.string(from: date)
                let val = goal.history[key] ?? 0
                result.append((date, val))
            }
        }
        return result.reversed() // Show oldest to newest (Left to Right)
    }
    
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.title3.weight(.bold))
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}