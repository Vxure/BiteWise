import Foundation

struct UserProfile: Identifiable {
    var id = UUID()
    var name: String
    var email: String
    var dietaryPreferences: [String]
    var allergies: [String]
    var macroGoals: MacroGoals
    
    struct MacroGoals {
        var dailyCalories: Int
        var proteinPercentage: Double
        var carbsPercentage: Double
        var fatsPercentage: Double
    }
}

// Dummy user profile data
extension UserProfile {
    static var dummy: UserProfile {
        UserProfile(
            name: "Regan",
            email: "regan@example.com",
            dietaryPreferences: ["High Protein", "Low Carb"],
            allergies: ["Peanuts", "Shellfish"],
            macroGoals: MacroGoals(
                dailyCalories: 2000,
                proteinPercentage: 30,
                carbsPercentage: 40,
                fatsPercentage: 30
            )
        )
    }
} 