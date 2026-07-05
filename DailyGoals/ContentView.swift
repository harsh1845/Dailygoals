import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var store: GoalStore
    @Binding var activeGoal: UUID?
    
    @State private var showingAddGoal = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Grid Configuration
    private var columns: [GridItem] {
        #if os(iOS)
        return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        #else
        return [GridItem(.adaptive(minimum: 200), spacing: 16)]
        #endif
    }

    var body: some View {
        TabView {
            // TAB 1: TODAY (Your existing main view)
            NavigationStack {
                ZStack {
                    AppBackground() // Your Aurora background
                    
                    VStack(spacing: 16) {
                        header
                        
                        if store.goals.isEmpty {
                            emptyState
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(store.goals) { goal in
                                        GoalTile(goal: goal, activeGoal: $activeGoal)
                                            .environmentObject(store)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Daily Goals")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddGoal = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                }
                .sheet(isPresented: $showingAddGoal) {
                    AddGoalView().environmentObject(store)
                }
            }
            .tabItem {
                Label("Today", systemImage: "list.bullet.circle.fill")
            }
            
            // TAB 2: HISTORY (The New Calendar)
            GlobalHistoryView()
                .environmentObject(store)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
        // Force the TabBar to be visible and distinct
        .tint(.white) // Selected color
        .onReceive(timer) { _ in store.tick() }
        #if os(iOS)
        .fullScreenCover(item: $activeGoal) { goalID in
            FocusView(goalID: goalID, activeGoal: $activeGoal)
        }
        #endif
    }

    // --- HEADER ---
    private var header: some View {
            let summary = store.summary()
            let percentage = summary.percentage
            let isOvertime = percentage > 1.0

            let totalXP = store.goals.reduce(0) { $0 + $1.rewardPoints }
            let bestStreak = store.goals.map(\.streak).max() ?? 0

            let standardGradient = LinearGradient(colors: GoalColors.all, startPoint: .leading, endPoint: .trailing)
            let overtimeGradient = LinearGradient(colors: [.yellow, .orange, .red], startPoint: .leading, endPoint: .trailing)
            let currentGradient = isOvertime ? overtimeGradient : standardGradient

            return VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Daily Progress")
                        .font(.headline)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("\(bestStreak)")
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            Text("\(totalXP) XP")
                        }
                    }
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Material.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .contentTransition(.numericText(value: percentage))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)

                    Text(isOvertime ? "Outstanding!" : summary.progressLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Spacer()
                }
            }
            .padding(24)
            .background {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.gray.opacity(0.15))
                        Rectangle()
                            .fill(currentGradient)
                            .frame(width: max(0, geo.size.width * CGFloat(percentage)))
                            .overlay(Color.black.opacity(0.1))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: percentage)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    
    // --- EMPTY STATE ---
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No goals set for today").font(.headline)
            Text("Tap the + button to create your first focus goal.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
