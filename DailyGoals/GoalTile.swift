import SwiftUI

struct GoalTile: View {
    let goal: Goal
    @Binding var activeGoal: UUID?
    @EnvironmentObject var store: GoalStore

    @State private var tick = 0

    var body: some View {
        let _ = tick

        let completed = store.displayedSeconds(for: goal)
        let target = max(goal.dailyQuotaSeconds, 1)
        let overtime = max(completed - target, 0)
        let progress = min(Double(completed) / Double(target), 1.0)
        let isRunning = goal.isActiveTimer

        VStack(spacing: 16) {

            // RING
            ZStack {
                Circle()
                    .stroke(lineWidth: 16)
                    .foregroundColor(.gray.opacity(0.25))

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor,
                            style: .init(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: completed)

                if overtime > 0 {
                    Circle()
                        .trim(from: 0,
                              to: min(Double(overtime) / Double(target), 1.0))
                        .stroke(Color.green,
                                style: .init(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: overtime)
                }

                VStack(spacing: 4) {
                    if completed < target {
                        Text(timeString(target - completed))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("+\(timeString(overtime))")
                            .foregroundColor(.green)
                            .font(.system(size: 22, weight: .bold))
                        Text("overtime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 140, height: 140)

            // Name
            Text(goal.name)
                .font(.headline)
                .multilineTextAlignment(.center)

            // Breakdown
            Text("\(timeString(completed)) / \(timeString(target))"
                 + (overtime > 0 ? " (+\(timeString(overtime)))" : ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Play/Pause
            Button(action: toggleTimer) {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 38))
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            tick += 1
        }
    }

    private func toggleTimer() {
        if goal.isActiveTimer {
            store.pauseTimer(for: goal)
            activeGoal = nil
        } else {
            store.startTimer(for: goal)
            activeGoal = goal.id
        }
    }
}
