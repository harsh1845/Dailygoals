import SwiftUI
import Combine

struct FocusView: View {
    @EnvironmentObject var store: GoalStore
    let goalID: UUID
    @Binding var activeGoal: UUID?

    @State private var tick = 0

    var body: some View {
        let _ = tick

        // Find the live goal by ID
        guard let goal = store.goals.first(where: { $0.id == goalID }) else {
            return AnyView(Color.clear)
        }

        let completed = store.displayedSeconds(for: goal)
        let target = max(goal.dailyQuotaSeconds, 1)
        let overtime = max(completed - target, 0)
        let progress = min(Double(completed) / Double(target), 1.0)
        let mood = GoalColors.all[goal.colorID]

        return AnyView(
            ZStack {
                // 1. NEW VIBRANT BACKGROUND
                FocusBackground()
                
                // Optional: Add a subtle color tint matching the specific goal on top
                mood.opacity(0.15)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)

                VStack(spacing: 30) {
                    Text(goal.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2) // Added shadow for contrast
                        .padding(.top, 50)

                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(lineWidth: 22)
                            .foregroundColor(.white.opacity(0.1))

                        // Main progress ring
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                mood,
                                style: .init(lineWidth: 22, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.2), value: completed)
                            // Make the ring glow
                            .shadow(color: mood.opacity(0.6), radius: 10, x: 0, y: 0)

                        // Overtime ring
                        if overtime > 0 {
                            Circle()
                                .trim(from: 0, to: min(Double(overtime) / Double(target), 1.0))
                                .stroke(Color.green,
                                        style: .init(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.2), value: overtime)
                                .shadow(color: .green.opacity(0.6), radius: 8)
                        }

                        VStack(spacing: 4) {
                            if completed < target {
                                Text(timeString(target - completed))
                                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                                Text("left")
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Text("+\(timeString(overtime))")
                                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                                    .foregroundColor(.green)
                                    .shadow(color: .black.opacity(0.5), radius: 2)
                                Text("overtime")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .frame(width: 300, height: 300)

                    Button {
                        store.pauseTimer(for: goal)
                        activeGoal = nil
                    } label: {
                        Text("Pause")
                            .font(.title2.bold())
                            .foregroundColor(mood)
                            .padding(.horizontal, 50)
                            .padding(.vertical, 16)
                            .background(Material.regular) // Glass button
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 5)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .onReceive(
                Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            ) { _ in
                tick += 1
            }
        )
    }

    private func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}
