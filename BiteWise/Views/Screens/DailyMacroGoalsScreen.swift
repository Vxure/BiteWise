import SwiftUI

struct DailyMacroGoalsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    // Current date formatted
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // Get macro goals from user profile
    private var goals: (calories: Int, protein: Int, carbs: Int, fats: Int) {
        dataManager.macroGoalsInGrams
    }
    
    // Calculate percentages for today
    private var todayCaloriesPercent: Int {
        guard goals.calories > 0 else { return 0 }
        return min(100, Int((Double(dataManager.dailyMacros.caloriesConsumed) / Double(goals.calories)) * 100))
    }
    
    private var todayProteinPercent: Int {
        guard goals.protein > 0 else { return 0 }
        return min(100, Int((dataManager.dailyMacros.proteinConsumed / Double(goals.protein)) * 100))
    }
    
    private var todayCarbsPercent: Int {
        guard goals.carbs > 0 else { return 0 }
        return min(100, Int((dataManager.dailyMacros.carbsConsumed / Double(goals.carbs)) * 100))
    }
    
    private var todayFatsPercent: Int {
        guard goals.fats > 0 else { return 0 }
        return min(100, Int((dataManager.dailyMacros.fatsConsumed / Double(goals.fats)) * 100))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Progress Card
                    todaysProgressCard
                    
                    // Macro Summary Grid
                    macroSummaryGrid
                    
                    // Weekly Progress Card
                    weeklyProgressCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Daily Macro Goals")
        .customNavigation()
    }
    
    // MARK: - Today's Progress Card
    private var todaysProgressCard: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(formattedDate)
                .font(.bwSubheadline())
                .foregroundColor(.secondary)
            
            // Streak badge
            let streak = dataManager.currentStreak
            if streak > 0 {
                HStack(spacing: 6) {
                    Text("🔥")
                    Text("\(streak) day streak")
                        .font(.bwSubheadline())
                        .fontWeight(.semibold)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            } else {
                HStack(spacing: 6) {
                    Text("🎯")
                    Text("Start tracking today!")
                        .font(.bwSubheadline())
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .bwCardStyle()
    }
    
    // MARK: - Macro Summary Grid
    private var macroSummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Calories with circular progress
            macroCard(
                title: "Calories",
                emoji: "🔥",
                current: dataManager.dailyMacros.caloriesConsumed,
                goal: goals.calories,
                percent: todayCaloriesPercent,
                color: Color.bwPrimaryCoral
            )
            
            // Protein
            macroCard(
                title: "Protein",
                emoji: "💪",
                current: Int(dataManager.dailyMacros.proteinConsumed),
                goal: goals.protein,
                percent: todayProteinPercent,
                color: Color.bwProtein,
                unit: "g"
            )
            
            // Carbs
            macroCard(
                title: "Carbs",
                emoji: "⚡️",
                current: Int(dataManager.dailyMacros.carbsConsumed),
                goal: goals.carbs,
                percent: todayCarbsPercent,
                color: Color.bwCarbs,
                unit: "g"
            )
            
            // Fat
            macroCard(
                title: "Fat",
                emoji: "🥑",
                current: Int(dataManager.dailyMacros.fatsConsumed),
                goal: goals.fats,
                percent: todayFatsPercent,
                color: Color.bwAccentRose,
                unit: "g"
            )
        }
    }
    
    private func macroCard(title: String, emoji: String, current: Int, goal: Int, percent: Int, color: Color, unit: String = "") -> some View {
        VStack(spacing: 12) {
            // Header with title and emoji
            HStack {
                Text(title)
                    .font(.bwHeadline())
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 32, height: 32)
                    
                    Text(emoji)
                        .font(.system(size: 16))
                }
            }
            
            // Circular progress with value inside
            ZStack {
                CircularProgressRing(
                    progress: Double(percent) / 100,
                    lineWidth: 8,
                    backgroundColor: Color.white.opacity(0.25),
                    foregroundColor: .white
                )
                .frame(width: 70, height: 70)
                
                VStack(spacing: 0) {
                    Text("\(percent)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.bwCaption2())
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Values
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("/ \(goal)\(unit)")
                    .font(.bwCaption())
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Shine overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Weekly Progress Card
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.bwTitle2())
                .padding(.bottom, 4)
            
            let recentLogs = dataManager.getRecentMacroLogs(days: 7)
            
            if recentLogs.isEmpty || recentLogs.allSatisfy({ $0.caloriesConsumed == 0 }) {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No tracking data yet")
                        .font(.bwBody())
                        .foregroundColor(.secondary)
                    
                    Text("Mark recipes as cooked to start tracking your macros")
                        .font(.bwCaption())
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentLogs.enumerated()), id: \.element.dateString) { index, log in
                        dailyProgressRow(
                            log: log,
                            goals: goals,
                            isToday: log.isToday
                        )
                        
                        if index < recentLogs.count - 1 {
                            Divider().padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle()
    }
    
    private func dailyProgressRow(log: DailyMacroLog, goals: (calories: Int, protein: Int, carbs: Int, fats: Int), isToday: Bool) -> some View {
        VStack(spacing: 10) {
            Text(isToday ? "Today" : log.displayDateString)
                .font(.bwHeadline())
                .foregroundColor(isToday ? Color.bwPrimaryCoral : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                macroProgressItem(
                    value: log.caloriesConsumed,
                    goal: goals.calories,
                    label: "Cal",
                    color: Color.bwPrimaryCoral
                )
                macroProgressItem(
                    value: Int(log.proteinConsumed),
                    goal: goals.protein,
                    label: "Pro",
                    color: Color.bwProtein
                )
                macroProgressItem(
                    value: Int(log.carbsConsumed),
                    goal: goals.carbs,
                    label: "Carb",
                    color: Color.bwCarbs
                )
                macroProgressItem(
                    value: Int(log.fatsConsumed),
                    goal: goals.fats,
                    label: "Fat",
                    color: Color.bwAccentRose
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    private func macroProgressItem(value: Int, goal: Int, label: String, color: Color) -> some View {
        let progress = goal > 0 ? min(1.0, Double(value) / Double(goal)) : 0
        
        return VStack(spacing: 4) {
            // Mini circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
            }
            
            Text(label)
                .font(.bwCaption2())
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.bwCaption())
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        DailyMacroGoalsScreen()
    }
}
