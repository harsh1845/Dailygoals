import SwiftUI

struct FocusView: View {
    @EnvironmentObject var store: GoalStore
    var goal: Goal
    @Binding var activeGoal: Goal?

    var body: some View {
        VStack(spacing: 40) {
            Text(goal.name)
                .font(.largeTitle.bold())

            Text(timeString(store.displayedSeconds(for: goal)))
                .font(.system(size: 50, weight: .bold, design: .rounded))

            Button("Exit Focus") {
                store.pauseTimer(for: goal)
                activeGoal = nil
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.9))
    }

    private func timeString(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}
