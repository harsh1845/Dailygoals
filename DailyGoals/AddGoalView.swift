import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var store: GoalStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedType: GoalType = .time
    
    // Time Inputs
    @State private var hoursText: String = "1"
    @State private var minutesText: String = "0"
    
    // Count Inputs
    @State private var countText: String = "5"

    @State private var scheduleType: ScheduleType = .everyDay
    @State private var customDays: Set<Int> = []   // 1...7

    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Add the Aurora Background
                AppBackground()
                
                // 2. The Form
                Form {
                    Section("Goal Info") {
                        TextField("Name", text: $name)
                        
                        Picker("Type", selection: $selectedType) {
                            Text("Timer").tag(GoalType.time)
                            Text("Counter").tag(GoalType.count)
                        }
                        .pickerStyle(.segmented)
                    }
                    // FIX: Wrap Material in a Rectangle so it counts as a View
                    .listRowBackground(Rectangle().fill(Material.thin))

                    Section("Target") {
                        if selectedType == .time {
                            HStack {
                                TextField("0", text: $hoursText)
                                    .labelsHidden()
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.roundedBorder)
                                Text("hrs")
                                
                                TextField("0", text: $minutesText)
                                    .labelsHidden()
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.roundedBorder)
                                Text("min")
                            }
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        } else {
                            HStack {
                                TextField("5", text: $countText)
                                    .labelsHidden()
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.roundedBorder)
                                Text("times per day")
                            }
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        }
                    }
                    // FIX: Wrap Material in a Rectangle
                    .listRowBackground(Rectangle().fill(Material.thin))

                    Section("Repeat") {
                        Picker("Repeat", selection: $scheduleType) {
                            ForEach(ScheduleType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        if scheduleType == .alternateDays {
                            Text("Repeats every other day starting today.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if scheduleType == .specificDays {
                            weekdayButtons
                        }
                    }
                    // FIX: Wrap Material in a Rectangle
                    .listRowBackground(Rectangle().fill(Material.thin))

                    Section("Reminder") {
                        Toggle("Daily notification", isOn: $reminderEnabled)
                        if reminderEnabled {
                            DatePicker(
                                "Remind me at",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                    .listRowBackground(Rectangle().fill(Material.thin))
                }
                // 3. Hide the default gray form background so Aurora shows through
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? Color.green : Color.gray)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if selectedType == .time {
            let h = Int(hoursText) ?? 0
            let m = Int(minutesText) ?? 0
            if h == 0 && m == 0 { return false }
        } else {
            let c = Int(countText) ?? 0
            if c <= 0 { return false }
        }

        if scheduleType == .specificDays {
            return !customDays.isEmpty
        }
        return true
    }

    private func saveGoal() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let targetValue: Int
        if selectedType == .time {
            let h = max(0, Int(hoursText) ?? 0)
            let m = max(0, Int(minutesText) ?? 0)
            targetValue = h * 3600 + m * 60
        } else {
            targetValue = max(1, Int(countText) ?? 1)
        }

        let days: [Int]? = scheduleType == .specificDays ? Array(customDays) : nil
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        store.addGoal(
            name: trimmed,
            type: selectedType,
            targetValue: targetValue,
            scheduleType: scheduleType,
            specificDays: days,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderEnabled ? timeComponents.hour : nil,
            reminderMinute: reminderEnabled ? timeComponents.minute : nil
        )
    }

    private var weekdayButtons: some View {
        let formatter = DateFormatter()
        formatter.locale = .current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S","M","T","W","T","F","S"]

        return HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { weekday in
                let label = symbols[weekday - 1]
                let selected = customDays.contains(weekday)
                Button {
                    if selected {
                        customDays.remove(weekday)
                    } else {
                        customDays.insert(weekday)
                    }
                } label: {
                    Text(label)
                        .font(.footnote.weight(.medium))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(selected ? Color.accentColor : Color.gray.opacity(0.3))
                        )
                        .foregroundStyle(selected ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
