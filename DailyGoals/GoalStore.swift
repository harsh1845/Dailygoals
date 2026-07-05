import Foundation

final class GoalStore: ObservableObject {
    @Published var goals: [Goal] = [] {
        didSet { save() }
    }

    private let storageKey = "DailyGoalsStorage"

    init() {
        load()
    }

    // MARK: - Public API

    func addGoal(name: String, hours: Int, minutes: Int) {
        let totalSeconds = hours * 3600 + minutes * 60
        guard totalSeconds > 0 else { return }

        let today = startOfDay(Date())
        let goal = Goal(
            name: name,
            dailyQuotaSeconds: totalSeconds,
            secondsCompletedToday: 0,
            lastResetDate: today
        )
        goals.append(goal)
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
    }

    func startTimer(for goal: Goal) {
        guard let idx = goals.firstIndex(of: goal) else { return }

        var g = goals[idx]
        let now = Date()
        let today = startOfDay(now)

        // If we're on a new day since last progress, roll over first
        if startOfDay(g.lastResetDate) < today {
            processDayChange(index: idx, todayStart: today)
            g = goals[idx]
        }

        // Don't start if already completed
        if displayedSeconds(for: g) >= g.dailyQuotaSeconds {
            return
        }

        // If already running, do nothing
        if g.isActiveTimer { return }

        g.isActiveTimer = true
        g.timerStartTimestamp = now
        goals[idx] = g
    }

    func pauseTimer(for goal: Goal) {
        guard let idx = goals.firstIndex(of: goal) else { return }
        var g = goals[idx]

        guard g.isActiveTimer, let start = g.timerStartTimestamp else { return }

        let elapsed = Int(Date().timeIntervalSince(start))
        g.secondsCompletedToday = min(
            g.dailyQuotaSeconds,
            g.secondsCompletedToday + max(0, elapsed)
        )

        g.isActiveTimer = false
        g.timerStartTimestamp = nil
        goals[idx] = g

        maybeGrantReward(index: idx)
    }

    /// For UI: includes live running time without mutating state
    func displayedSeconds(for goal: Goal) -> Int {
        if goal.isActiveTimer, let start = goal.timerStartTimestamp {
            let elapsed = Int(Date().timeIntervalSince(start))
            let total = goal.secondsCompletedToday + max(0, elapsed)
            return min(total, goal.dailyQuotaSeconds)
        } else {
            return min(goal.secondsCompletedToday, goal.dailyQuotaSeconds)
        }
    }

    /// Called every second from the UI
    func tick() {
        let now = Date()
        let todayStart = startOfDay(now)

        for idx in goals.indices {
            // Handle day rollover (rewards / punishments + reset)
            if startOfDay(goals[idx].lastResetDate) < todayStart {
                processDayChange(index: idx, todayStart: todayStart)
            }

            // Auto-stop timers when quota reached
            if goals[idx].isActiveTimer, let start = goals[idx].timerStartTimestamp {
                let elapsed = Int(now.timeIntervalSince(start))
                let total = goals[idx].secondsCompletedToday + max(0, elapsed)

                if total >= goals[idx].dailyQuotaSeconds {
                    var g = goals[idx]
                    g.secondsCompletedToday = g.dailyQuotaSeconds
                    g.isActiveTimer = false
                    g.timerStartTimestamp = nil
                    goals[idx] = g
                    maybeGrantReward(index: idx)
                }
            }
        }
    }

    // MARK: - Private helpers

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Handle end-of-day: reward/punish and reset counters
    private func processDayChange(index: Int, todayStart: Date) {
        var g = goals[index]

        // Finalise any running timer, using midnight as cutoff
        if g.isActiveTimer, let start = g.timerStartTimestamp {
            let elapsed = Int(todayStart.timeIntervalSince(start))
            g.secondsCompletedToday = min(
                g.dailyQuotaSeconds,
                g.secondsCompletedToday + max(0, elapsed)
            )
            g.isActiveTimer = false
            g.timerStartTimestamp = nil
        }

        let completedYesterday = g.secondsCompletedToday >= g.dailyQuotaSeconds

        if completedYesterday {
            // If they never got their XP for yesterday, grant it now
            if !g.hasEarnedRewardToday {
                let reward = max(1, g.dailyQuotaSeconds / 60)
                g.rewardPoints += reward
                g.streak += 1
                g.hasEarnedRewardToday = true
            }
        } else {
            // Punishment: lose some points + streak reset
            g.rewardPoints = max(0, g.rewardPoints - 10)
            g.streak = 0
        }

        // New day reset
        g.secondsCompletedToday = 0
        g.lastResetDate = todayStart
        g.hasEarnedRewardToday = false   // for the *new* day

        goals[index] = g
    }

    private func maybeGrantReward(index: Int) {
        var g = goals[index]
        let total = displayedSeconds(for: g)

        guard total >= g.dailyQuotaSeconds, !g.hasEarnedRewardToday else { return }

        let reward = max(1, g.dailyQuotaSeconds / 60) // 1 XP per min, min 1
        g.rewardPoints += reward
        g.streak += 1
        g.hasEarnedRewardToday = true

        goals[index] = g
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save goals: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            goals = []
            return
        }

        do {
            goals = try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("Failed to load goals: \(error)")
            goals = []
        }
    }
}
