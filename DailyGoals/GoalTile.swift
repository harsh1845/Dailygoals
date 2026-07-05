import SwiftUI
import Combine

struct GoalTile: View {
    let goal: Goal
    @Binding var activeGoal: UUID?
    @EnvironmentObject var store: GoalStore
    
    @State private var showEdit = false
    
    // Animation States
    @State private var showConfetti = false
    @State private var scale: CGFloat = 1.0
    @State private var hasCelebrated = false
    @State private var showHistory = false

    #if os(macOS)
    @State private var isHovering = false
    #endif
    
    // MARK: - Platform Specific Settings
    // These variables switch values automatically based on the device
    #if os(iOS)
    private let ringSize: CGFloat = 100       // Smaller ring for iPhone
    private let strokeWidth: CGFloat = 12     // Thinner lines
    private let centerFontSize: CGFloat = 18  // Smaller text inside ring
    private let buttonSize: CGFloat = 38      // Compact buttons
    private let vStackSpacing: CGFloat = 12   // Tighter spacing
    #else
    private let ringSize: CGFloat = 140       // Big ring for Mac
    private let strokeWidth: CGFloat = 16     // Bold lines
    private let centerFontSize: CGFloat = 22  // Big text
    private let buttonSize: CGFloat = 44      // Large buttons
    private let vStackSpacing: CGFloat = 16   // Relaxed spacing
    #endif

    var body: some View {
        let currentVal: Int
        let targetVal: Int
        
        if goal.type == .time {
            currentVal = store.displayedSeconds(for: goal)
            targetVal = max(goal.dailyQuotaSeconds, 1)
        } else {
            currentVal = goal.currentCount
            targetVal = max(goal.targetCount, 1)
        }
        
        let overtime = max(currentVal - targetVal, 0)
        let isRunning = goal.isActiveTimer
        let mainProgress = min(Double(currentVal) / Double(targetVal), 1.0)
        let overtimeProgress = min(Double(overtime) / Double(targetVal), 1.0)
        
        return VStack(spacing: vStackSpacing) { // Use dynamic spacing
            
            // RING VIEW
            ZStack {
                Circle()
                    .stroke(lineWidth: strokeWidth)
                    .foregroundColor(.gray.opacity(0.25))

                Circle()
                    .trim(from: 0, to: mainProgress)
                    .stroke(GoalColors.all[goal.colorID],
                            style: .init(lineWidth: strokeWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: mainProgress)

                if overtime > 0 {
                    Circle()
                        .trim(from: 0, to: overtimeProgress)
                        .stroke(Color.green,
                                style: .init(lineWidth: strokeWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: overtimeProgress)
                }

                VStack(spacing: 2) {
                    if overtime > 0 {
                        let text = goal.type == .time
                            ? "+\(timeString(overtime))"
                            : "+\(overtime)"
                        
                        Text(text)
                            .font(.system(size: centerFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("overtime")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        if goal.type == .time {
                            let left = max(targetVal - currentVal, 0)
                            Text(timeString(left))
                                .font(.system(size: centerFontSize, weight: .bold, design: .rounded))
                            Text("left")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(currentVal) / \(targetVal)")
                                .font(.system(size: centerFontSize, weight: .bold, design: .rounded))
                            Text("done")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    showEdit = true
                }
            }
            .frame(width: ringSize, height: ringSize) // Use dynamic size
            .overlay {
                if showConfetti {
                    ConfettiView()
                }
            }
            .scaleEffect(scale)

            // Name
            HStack {
                Text(goal.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                // Small info button to see history
                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Controls
            if goal.type == .time {
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: buttonSize)) // Dynamic button size
                        .foregroundStyle(isRunning ? Color.orange : Color.green)
                }
                .buttonStyle(.borderless)
            } else {
                HStack(spacing: 20) {
                    Button {
                        store.incrementCount(for: goal, by: -1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: buttonSize - 8)) // Slightly smaller minus
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    
                    Button {
                        store.incrementCount(for: goal, by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: buttonSize)) // Dynamic plus
                            .foregroundStyle(Color.green)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            GoalColors.all[goal.colorID].opacity(0.8),
                            GoalColors.all[goal.colorID].opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        // --- Celebration Logic ---
        .onChange(of: currentVal) { newValue in
            if newValue >= targetVal && !hasCelebrated {
                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif
                
                showConfetti = true
                hasCelebrated = true
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.15
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { scale = 1.0 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showConfetti = false
                }
            } else if newValue < targetVal {
                hasCelebrated = false
            }
        }
        .sheet(isPresented: $showEdit) {
            EditGoalView(goalID: goal.id)
                .environmentObject(store)
        }
        .sheet(isPresented: $showHistory) {
            TaskHistoryView(goal: goal) // <--- Opens the chart view we made
        }
        #if os(macOS)
            .overlay(alignment: .topTrailing) {
                 if isHovering {
                     Button {
                         store.deleteGoal(goal)
                     } label: {
                         Image(systemName: "trash.circle.fill")
                             .font(.title2)
                             .foregroundStyle(.red)
                     }
                     .buttonStyle(.plain)
                     .padding(8)
                 }
            }
            .onHover { hover in withAnimation { isHovering = hover } }
        #endif
        .contextMenu {
            Button(role: .destructive) {
                store.deleteGoal(goal)
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
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

private func timeString(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    if h > 0 {
        return String(format: "%d:%02d", h, m)
    } else {
        return String(format: "%02d:%02d", m, seconds % 60)
    }
}
