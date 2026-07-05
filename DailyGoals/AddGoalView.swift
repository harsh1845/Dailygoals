import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var store: GoalStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var hours: Int = 1
    @State private var minutes: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $name)
                }

                Section("Daily time target") {
                    Stepper("\(hours) hour\(hours == 1 ? "" : "s")",
                            value: $hours,
                            in: 0...12)

                    Stepper("\(minutes) minutes",
                            value: $minutes,
                            in: 0...55,
                            step: 5)
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.addGoal(name: trimmed, hours: hours, minutes: minutes)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && (hours > 0 || minutes > 0)
    }
}
