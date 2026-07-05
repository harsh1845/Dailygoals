import SwiftUI

struct GlobalHistoryView: View {
    @EnvironmentObject var store: GoalStore
    @State private var selectedDate: Date = Date()
    @State private var calendarDate: Date = Date() // Used for navigating months
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground() // Aurora background
                
                VStack(spacing: 20) {
                    // 1. Calendar Header (Month + Arrows)
                    HStack {
                        Button { shiftMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(monthYearString(from: calendarDate))
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Button { shiftMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                    }
                    .padding(.horizontal)
                    .foregroundStyle(.white)
                    
                    // 2. The Calendar Grid
                    LazyVGrid(columns: columns, spacing: 15) {
                        // Day Names
                        ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                            Text(day).font(.caption).foregroundStyle(.secondary)
                        }
                        
                        // Days
                        let days = daysInMonth()
                        ForEach(days, id: \.self) { date in
                            if let date = date {
                                dayCell(for: date)
                            } else {
                                Text("") // Empty spacer for offset
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Selected Day Detail List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Activity for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                let historyItems = getHistoryForSelectedDate()
                                if historyItems.isEmpty {
                                    Text("No activity recorded.")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 20)
                                } else {
                                    ForEach(historyItems, id: \.goalID) { item in
                                        HStack {
                                            Circle()
                                                .fill(GoalColors.all[item.colorID])
                                                .frame(width: 12, height: 12)
                                            Text(item.name).bold()
                                            Spacer()
                                            Text(item.valueStr)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("History")
        }
    }
    
    // MARK: - Subviews
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasActivity = checkActivity(for: date)
        
        return Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 16, weight: isSelected ? .bold : .regular))
            .frame(width: 35, height: 35)
            .background(isSelected ? Color.white : Color.clear)
            .foregroundStyle(isSelected ? Color.black : (isToday ? Color.blue : Color.white))
            .clipShape(Circle())
            .overlay(alignment: .bottom) {
                if hasActivity && !isSelected {
                    Circle().fill(Color.green).frame(width: 4, height: 4).offset(y: 4)
                }
            }
            .onTapGesture {
                withAnimation { selectedDate = date }
            }
    }
    
    // MARK: - Logic
    func shiftMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: calendarDate) {
            calendarDate = newDate
        }
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: calendarDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendarDate))
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Add nil for offset days (e.g., if month starts on Wednesday)
        let offsetDays = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        let days = range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)
        }
        
        return offsetDays + days
    }
    
    func checkActivity(for date: Date) -> Bool {
        let key = dateKey(for: date)
        return store.goals.contains { $0.history[key] != nil }
    }
    
    func getHistoryForSelectedDate() -> [(goalID: UUID, name: String, colorID: Int, valueStr: String)] {
        let key = dateKey(for: selectedDate)
        var results: [(UUID, String, Int, String)] = []
        
        for goal in store.goals {
            if let val = goal.history[key] {
                let displayStr = goal.type == .time ? formatTime(val) : "\(val) times"
                results.append((goal.id, goal.name, goal.colorID, displayStr))
            }
        }
        return results
    }
    
    func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    
    func formatTime(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}