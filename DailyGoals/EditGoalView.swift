//
//  EditGoalView.swift
//  DailyGoals
//
//  Created by harsh selarka on 30/11/2025.
//


import SwiftUI

struct EditGoalView: View {
    @EnvironmentObject var store: GoalStore
    @Environment(\.dismiss) private var dismiss
    
    let goalID: UUID
    
    // Local state for editing
    @State private var name: String = ""
    @State private var currentCount: String = "0"
    @State private var targetCount: String = "0"
    
    @State private var targetHours: String = "0"
    @State private var targetMinutes: String = "0"
    @State private var currentHours: String = "0"
    @State private var currentMinutes: String = "0"

    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Reuse your Aurora background
                AppBackground()
                
                if let index = store.goals.firstIndex(where: { $0.id == goalID }) {
                    let goal = store.goals[index]
                    
                    Form {
                        Section("Goal Details") {
                            TextField("Name", text: $name)
                        }
                        .listRowBackground(Rectangle().fill(Material.thin))
                        
                        Section("Progress & Target") {
                            if goal.type == .time {
                                // TIME EDITING
                                LabeledContent("Current Logged") {
                                    HStack {
                                        TextField("H", text: $currentHours).frame(width: 40)
                                        Text("h")
                                        TextField("M", text: $currentMinutes).frame(width: 40)
                                        Text("m")
                                    }
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.roundedBorder)
                                }
                                
                                LabeledContent("Daily Goal") {
                                    HStack {
                                        TextField("H", text: $targetHours).frame(width: 40)
                                        Text("h")
                                        TextField("M", text: $targetMinutes).frame(width: 40)
                                        Text("m")
                                    }
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.roundedBorder)
                                }
                            } else {
                                // COUNT EDITING
                                LabeledContent("Current Count") {
                                    TextField("0", text: $currentCount)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                
                                LabeledContent("Target Count") {
                                    TextField("0", text: $targetCount)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                            }
                        }
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
                        
                        Section {
                            Button("Delete Goal", role: .destructive) {
                                store.deleteGoal(goal)
                                dismiss()
                            }
                        }
                        .listRowBackground(Rectangle().fill(Material.thin))
                    }
                    .scrollContentBackground(.hidden)
                    .onAppear {
                        // Load data into state variables
                        name = goal.name
                        
                        if goal.type == .count {
                            currentCount = String(goal.currentCount)
                            targetCount = String(goal.targetCount)
                        } else {
                            // Convert Seconds to Hours/Minutes for Target
                            targetHours = String(goal.dailyQuotaSeconds / 3600)
                            targetMinutes = String((goal.dailyQuotaSeconds % 3600) / 60)
                            
                            // Convert Seconds to Hours/Minutes for Current Progress
                            currentHours = String(goal.secondsCompletedToday / 3600)
                            currentMinutes = String((goal.secondsCompletedToday % 3600) / 60)
                        }

                        reminderEnabled = goal.reminderEnabled
                        reminderTime = goal.reminderDate
                    }
                } else {
                    Text("Goal not found")
                }
            }
            .navigationTitle("Edit Goal")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundStyle(Color.green)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
        #endif
    }
    
    private func saveChanges() {
        guard let index = store.goals.firstIndex(where: { $0.id == goalID }) else { return }
        
        var updatedGoal = store.goals[index]
        updatedGoal.name = name
        
        if updatedGoal.type == .count {
            updatedGoal.currentCount = Int(currentCount) ?? updatedGoal.currentCount
            updatedGoal.targetCount = max(1, Int(targetCount) ?? updatedGoal.targetCount)
        } else {
            // Save Target
            let tH = Int(targetHours) ?? 0
            let tM = Int(targetMinutes) ?? 0
            updatedGoal.dailyQuotaSeconds = (tH * 3600) + (tM * 60)
            
            // Save Current Progress
            let cH = Int(currentHours) ?? 0
            let cM = Int(currentMinutes) ?? 0
            updatedGoal.secondsCompletedToday = (cH * 3600) + (cM * 60)
        }

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        updatedGoal.reminderEnabled = reminderEnabled
        updatedGoal.reminderHour = reminderEnabled ? timeComponents.hour : nil
        updatedGoal.reminderMinute = reminderEnabled ? timeComponents.minute : nil
        
        store.updateGoal(updatedGoal)
    }
}
