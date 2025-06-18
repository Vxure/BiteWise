import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    
    // Time-based greeting
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    // Next meal suggestion based on time
    private var nextMeal: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<11: return "Breakfast"
        case 11..<15: return "Lunch"
        case 15..<18: return "Snack"
        default: return "Dinner"
        }
    }
    
    var body: some View {
        ZStack {
            // Diagonal gradient background - ensure it's the first element in the ZStack
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFC78E").opacity(0.8),  // Warm pastel orange
                    Color(hex: "A1C4FD").opacity(0.8)   // Soft blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content ScrollView with transparent background
            ScrollView {
                Spacer()
                    .frame(height: 10) // Small additional spacing at the top
                
                VStack(alignment: .leading, spacing: 10) {
                    // MARK: - Header with Title and Profile
                    HStack {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading, 10)
                        
                        Spacer()
                        
                        Button(action: {
                            navigationState.navigateTo(.userProfile)
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.primary)
                                .padding(.trailing, 10)
                        }
                    }
                    .padding(.top, 15) // Increased top padding to ensure content is below safe area
                    
                    // MARK: - Greeting Header
                    greetingHeaderSection
                    
                    // MARK: - Recently Cooked
                    recentlyCookedSection
                    
                    // MARK: - Macro Overview
                    macroOverviewSection
                    
                    // MARK: - Up Next Suggestion
                    upNextSection
                    
                    // MARK: - Recent Activity
                    recentActivitySection
                    
                    // MARK: - Running Low
                    runningLowSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 1) // Ensures content respects top safe area
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80) // Increased height for floating tab bar
            }
            .background(Color.clear) // Explicitly set ScrollView background to clear
        }
    }
    
    // MARK: - Greeting Header
    private var greetingHeaderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("👋 Good \(timeOfDay), Regan!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ready to cook something good?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Recently Cooked
    private var recentlyCookedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Cooked")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Recently cooked recipe 1
                    recentlyRecipeCard(
                        title: "Pasta Carbonara",
                        date: "Yesterday",
                        color: Color(hex: "FF9500").opacity(0.2),
                        systemImage: "fork.knife"
                    )
                    
                    // Recently cooked recipe 2
                    recentlyRecipeCard(
                        title: "Chicken Stir Fry",
                        date: "2 days ago",
                        color: Color(hex: "30D158").opacity(0.2),
                        systemImage: "flame"
                    )
                    
                    // Recently cooked recipe 3
                    recentlyRecipeCard(
                        title: "Mushroom Risotto",
                        date: "Last week",
                        color: Color(hex: "A45DE8").opacity(0.2),
                        systemImage: "leaf"
                    )
                }
                .padding(.bottom, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func recentlyRecipeCard(title: String, date: String, color: Color, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(height: 100)
                
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(color.opacity(2))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 12)
        }
        .frame(width: 160)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Macro Overview
    private var macroOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    navigationState.navigateTo(.dailyMacroGoals)
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "4285F4"))
                }
            }
            
            HStack(spacing: 16) {
                // Calories card
                Button(action: {
                    navigationState.navigateTo(.dailyMacroGoals)
                }) {
                    macroCardView(
                        title: "Calories",
                        value: "1650",
                        goal: "of 2000",
                        progress: 0.83,
                        icon: "flame",
                        color: Color(hex: "4285F4") // Blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Protein card
                Button(action: {
                    navigationState.navigateTo(.dailyMacroGoals)
                }) {
                    macroCardView(
                        title: "Protein",
                        value: "128g",
                        goal: "of 150g",
                        progress: 0.85,
                        icon: "figure.strengthtraining.traditional",
                        color: Color(hex: "34A853") // Green
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func macroCardView(title: String, value: String, goal: String, progress: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 4)
            
            Text(goal)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: CGFloat(progress) * (UIScreen.main.bounds.width / 2 - 40), height: 6)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
        )
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Up Next Suggestion
    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Up Next")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                // Recipe image/icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "30D158").opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "flame")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "30D158"))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextMeal)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Chicken Stir Fry")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Ready in 25 minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 2) {
                activityItem(
                    icon: "checkmark.circle.fill",
                    text: "You cooked Pasta Carbonara",
                    time: "Yesterday",
                    color: Color(hex: "FF9500")
                )
                
                Divider()
                    .padding(.leading, 40)
                
                activityItem(
                    icon: "plus.circle.fill",
                    text: "Added Garlic to Pantry",
                    time: "2 days ago",
                    color: Color(hex: "30D158")
                )
                
                Divider()
                    .padding(.leading, 40)
                
                activityItem(
                    icon: "heart.fill",
                    text: "Liked Mushroom Risotto",
                    time: "Last week",
                    color: Color(hex: "A45DE8")
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func activityItem(icon: String, text: String, time: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Running Low
    private var runningLowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Running Low")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                runningLowItem(
                    ingredient: "Eggs",
                    message: "You've used Eggs a lot lately — might be running low!"
                )
                
                Divider()
                    .padding(.leading, 50)
                
                runningLowItem(
                    ingredient: "Garlic",
                    message: "Last added 2 weeks ago. Time to restock?"
                )
                
                Divider()
                    .padding(.leading, 50)
                
                runningLowItem(
                    ingredient: "Rice",
                    message: "Used in 3 recipes this week. Check your supply!"
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func runningLowItem(ingredient: String, message: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF9500").opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("🛒")
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {
                // Action to add to shopping list or mark as purchased
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color(hex: "30D158"))
                    .font(.system(size: 24))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppNavigationState())
} 
 
