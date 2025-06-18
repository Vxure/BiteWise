import SwiftUI

struct DailyMacroGoalsScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    // Custom colors
    private let caloriesColor = Color(hex: "4285F4")  // Blue
    private let proteinColor = Color(hex: "34A853")   // Green
    private let carbsColor = Color(hex: "FBBC05")     // Orange/Yellow
    private let fatColor = Color(hex: "A142F4")       // Purple
    
    // Current date formatted
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's Progress Card
                todaysProgressCard
                
                // Macro Summary Grid
                macroSummaryGrid
                
                // Weekly Progress Card
                weeklyProgressCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Daily Macro Goals")
    }
    
    // MARK: - Today's Progress Card
    private var todaysProgressCard: some View {
        VStack(spacing: 20) {
            Text("Today's Progress")
                .font(.system(size: 32, weight: .bold))
            
            Text(formattedDate)
                .font(.title3)
                .foregroundColor(.secondary)
            
            // Streak badge
            Text("🔥 7 day streak")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Macro Summary Grid
    private var macroSummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Calories
            macroCard(
                title: "Calories",
                emoji: "🔥",
                current: 1650,
                goal: 2000,
                percent: 83,
                color: caloriesColor
            )
            
            // Protein
            macroCard(
                title: "Protein",
                emoji: "💪",
                current: 128,
                goal: 150,
                percent: 85,
                color: proteinColor,
                unit: "g"
            )
            
            // Carbs
            macroCard(
                title: "Carbs",
                emoji: "⚡️",
                current: 145,
                goal: 200,
                percent: 73,
                color: carbsColor,
                unit: "g"
            )
            
            // Fat
            macroCard(
                title: "Fat",
                emoji: "🥑",
                current: 52,
                goal: 67,
                percent: 78,
                color: fatColor,
                unit: "g"
            )
        }
    }
    
    private func macroCard(title: String, emoji: String, current: Int, goal: Int, percent: Int, color: Color, unit: String = "") -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 36)
                    
                    Text(emoji)
                        .font(.system(size: 18))
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("/ \(goal)\(unit)")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: CGFloat(percent) / 100 * (UIScreen.main.bounds.width / 2 - 40), height: 8)
            }
            
            Text("\(percent)% complete")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color)
        )
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Weekly Progress Card
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Progress")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            
            // June 10
            dailyProgressRow(
                date: "Jun 10", 
                calories: (1800, 2000),
                protein: (132, 150),
                carbs: (144, 200),
                fat: (57, 67)
            )
            
            // June 11
            dailyProgressRow(
                date: "Jun 11", 
                calories: (1560, 2000),
                protein: (138, 150),
                carbs: (136, 200),
                fat: (60, 67)
            )
            
            // June 12
            dailyProgressRow(
                date: "Jun 12", 
                calories: (1760, 2000),
                protein: (128, 150),
                carbs: (150, 200),
                fat: (55, 67)
            )
            
            // June 13
            dailyProgressRow(
                date: "Jun 13", 
                calories: (1840, 2000),
                protein: (135, 150),
                carbs: (160, 200),
                fat: (59, 67)
            )
            
            // June 14
            dailyProgressRow(
                date: "Jun 14", 
                calories: (1700, 2000),
                protein: (143, 150),
                carbs: (146, 200),
                fat: (52, 67)
            )
            
            // June 15
            dailyProgressRow(
                date: "Jun 15", 
                calories: (1800, 2000),
                protein: (131, 150),
                carbs: (170, 200),
                fat: (62, 67)
            )
            
            // Today
            dailyProgressRow(
                date: "Today", 
                calories: (1650, 2000),
                protein: (128, 150),
                carbs: (145, 200),
                fat: (52, 67)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func dailyProgressRow(date: String, calories: (Int, Int), protein: (Int, Int), carbs: (Int, Int), fat: (Int, Int)) -> some View {
        VStack(spacing: 8) {
            Text(date)
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)
            
            HStack(spacing: 10) {
                // Calories progress
                macroProgressItem(
                    value: calories.0,
                    goal: calories.1,
                    label: "Cals",
                    color: caloriesColor
                )
                
                // Protein progress
                macroProgressItem(
                    value: protein.0,
                    goal: protein.1,
                    label: "Protein",
                    color: proteinColor
                )
                
                // Carbs progress
                macroProgressItem(
                    value: carbs.0,
                    goal: carbs.1,
                    label: "Carbs",
                    color: carbsColor
                )
                
                // Fat progress
                macroProgressItem(
                    value: fat.0,
                    goal: fat.1,
                    label: "Fats",
                    color: fatColor
                )
            }
        }
        .padding(.vertical, 10)
    }
    
    private func macroProgressItem(value: Int, goal: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            // Progress bar with rounded corners
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: CGFloat(value) / CGFloat(goal) * (UIScreen.main.bounds.width - 120) / 4, height: 8)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            
            Text("\(value)/\(goal)")
                .font(.caption)
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