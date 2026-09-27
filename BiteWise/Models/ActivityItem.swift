import Foundation
import SwiftUI

/// Represents a user activity that can be displayed in the Recent Activity section
struct ActivityItem: Identifiable, Codable {
    var id = UUID()
    var type: ActivityType
    var title: String
    var timestamp: Date
    var relatedId: UUID?  // Recipe or ingredient ID if applicable
    
    /// Types of activities that can be logged
    enum ActivityType: String, Codable {
        case cookedRecipe
        case addedPantryItem
        case addedFridgeItem
        case ratedRecipe
        case favoritedRecipe
        case submittedFeedback
    }
}

// MARK: - Database Mapping
extension ActivityItem.ActivityType {
    /// Value stored in `activity_feed.activity_type`. Must match the table's CHECK constraint.
    /// `rawValue` stays camelCase because it is persisted locally via Codable.
    var databaseValue: String {
        switch self {
        case .cookedRecipe: return "cooked_recipe"
        case .addedPantryItem: return "added_pantry_item"
        case .addedFridgeItem: return "added_fridge_item"
        case .ratedRecipe: return "rated_recipe"
        case .favoritedRecipe: return "favorited_recipe"
        case .submittedFeedback: return "submitted_feedback"
        }
    }

    init?(databaseValue: String) {
        switch databaseValue {
        case "cooked_recipe": self = .cookedRecipe
        case "added_pantry_item": self = .addedPantryItem
        case "added_fridge_item": self = .addedFridgeItem
        case "rated_recipe": self = .ratedRecipe
        case "favorited_recipe": self = .favoritedRecipe
        case "submitted_feedback": self = .submittedFeedback
        default: return nil
        }
    }
}

// MARK: - Display Properties
extension ActivityItem {
    /// Icon to display for this activity type
    var icon: String {
        switch type {
        case .cookedRecipe:
            return "checkmark.circle.fill"
        case .addedPantryItem:
            return "plus.circle.fill"
        case .addedFridgeItem:
            return "refrigerator.fill"
        case .ratedRecipe:
            return "star.fill"
        case .favoritedRecipe:
            return "bookmark.fill"
        case .submittedFeedback:
            return "bubble.left.and.bubble.right.fill"
        }
    }
    
    /// Color associated with this activity type
    var color: Color {
        switch type {
        case .cookedRecipe:
            return Color.bwCarbs
        case .addedPantryItem:
            return Color.bwPrimary
        case .addedFridgeItem:
            return Color.bwAccentBlue
        case .ratedRecipe:
            return Color.bwAccentGold
        case .favoritedRecipe:
            return Color.bwAccent
        case .submittedFeedback:
            return Color.bwSecondary
        }
    }
    
    /// Human-readable time ago string
    var timeAgoString: String {
        TimeFormatter.timeAgo(from: timestamp)
    }
}

// MARK: - Factory Methods
extension ActivityItem {
    /// Create an activity for cooking a recipe
    static func cookedRecipe(_ recipe: Recipe) -> ActivityItem {
        ActivityItem(
            type: .cookedRecipe,
            title: "Cooked \(recipe.title)",
            timestamp: Date(),
            relatedId: recipe.id
        )
    }
    
    /// Create an activity for adding a pantry item
    static func addedPantryItem(_ ingredient: Ingredient) -> ActivityItem {
        ActivityItem(
            type: .addedPantryItem,
            title: "Added \(ingredient.name) to Pantry",
            timestamp: Date(),
            relatedId: ingredient.id
        )
    }
    
    /// Create an activity for adding a fridge item
    static func addedFridgeItem(_ item: FridgeItem) -> ActivityItem {
        ActivityItem(
            type: .addedFridgeItem,
            title: "Added \(item.name) to Fridge",
            timestamp: Date(),
            relatedId: item.id
        )
    }
    
    /// Create an activity for rating a recipe
    static func ratedRecipe(_ recipe: Recipe, rating: Int) -> ActivityItem {
        let starsText = rating == 1 ? "star" : "stars"
        return ActivityItem(
            type: .ratedRecipe,
            title: "Rated \(recipe.title) \(rating) \(starsText)",
            timestamp: Date(),
            relatedId: recipe.id
        )
    }
    
    /// Create an activity for favoriting a recipe
    static func favoritedRecipe(_ recipe: Recipe) -> ActivityItem {
        ActivityItem(
            type: .favoritedRecipe,
            title: "Saved \(recipe.title)",
            timestamp: Date(),
            relatedId: recipe.id
        )
    }
    
    /// Create an activity for submitting recipe feedback
    static func submittedFeedback(_ feedback: RecipeFeedback) -> ActivityItem {
        ActivityItem(
            type: .submittedFeedback,
            title: "Left feedback on \(feedback.recipeName)",
            timestamp: Date(),
            relatedId: feedback.recipeId
        )
    }
}

