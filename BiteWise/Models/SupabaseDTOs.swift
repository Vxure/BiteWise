//
//  SupabaseDTOs.swift
//  BiteWise
//
//  Data Transfer Objects for Supabase tables.
//  These structs map directly to database tables with snake_case conversion.
//

import Foundation

// MARK: - Profile DTO
/// Maps to `profiles` table
struct ProfileDTO: Codable, Identifiable {
    let id: UUID
    var name: String?
    var email: String?
    var avatarUrl: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Preferences DTO
/// Maps to `user_preferences` table
struct UserPreferencesDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var dietaryPreferences: [String]
    var allergies: [String]
    var dailyCalories: Int
    var proteinPercentage: Double
    var carbsPercentage: Double
    var fatsPercentage: Double
    var hasMacroGoals: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dietaryPreferences = "dietary_preferences"
        case allergies
        case dailyCalories = "daily_calories"
        case proteinPercentage = "protein_percentage"
        case carbsPercentage = "carbs_percentage"
        case fatsPercentage = "fats_percentage"
        case hasMacroGoals = "has_macro_goals"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Settings DTO
/// Maps to `user_settings` table
struct UserSettingsDTO: Codable {
    let userId: UUID
    var fridgeAutoExpireEnabled: Bool
    var fridgeAutoExpireDays: Int
    var chatAutoExpireEnabled: Bool
    var generalChatExpireDays: Int
    var recipeChatExpireDays: Int
    var keepRecipeChatsLonger: Bool
    var defaultScanMethod: String
    var lastFridgeClearAt: Date?
    var lastPantryClearAt: Date?
    var lastChatClearAt: Date?
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fridgeAutoExpireEnabled = "fridge_auto_expire_enabled"
        case fridgeAutoExpireDays = "fridge_auto_expire_days"
        case chatAutoExpireEnabled = "chat_auto_expire_enabled"
        case generalChatExpireDays = "general_chat_expire_days"
        case recipeChatExpireDays = "recipe_chat_expire_days"
        case keepRecipeChatsLonger = "keep_recipe_chats_longer"
        case defaultScanMethod = "default_scan_method"
        case lastFridgeClearAt = "last_fridge_clear_at"
        case lastPantryClearAt = "last_pantry_clear_at"
        case lastChatClearAt = "last_chat_clear_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Ingredient Catalog DTO
/// Maps to `ingredients` table (shared catalog)
struct IngredientCatalogDTO: Codable, Identifiable {
    let id: UUID
    var name: String
    var normalizedName: String
    var category: String
    var isCommon: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case normalizedName = "normalized_name"
        case category
        case isCommon = "is_common"
        case createdAt = "created_at"
    }
}

// MARK: - Fridge Scan DTO
/// Maps to `fridge_scans` table
struct FridgeScanDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var imagePath: String?
    var scannedAt: Date
    var mergeMode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imagePath = "image_path"
        case scannedAt = "scanned_at"
        case mergeMode = "merge_mode"
    }
}

// MARK: - Fridge Item DTO
/// Maps to `fridge_items` table
struct FridgeItemDTO: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    var scanId: UUID?
    var ingredientId: UUID?
    var name: String
    var quantity: String
    var category: String
    var isStaple: Bool
    var dateAdded: Date
    var expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scanId = "scan_id"
        case ingredientId = "ingredient_id"
        case name
        case quantity
        case category
        case isStaple = "is_staple"
        case dateAdded = "date_added"
        case expiresAt = "expires_at"
    }
    
    /// Convert from local FridgeItem model
    init(from item: FridgeItem, userId: UUID) {
        self.id = item.id
        self.userId = userId
        self.scanId = nil
        self.ingredientId = nil
        self.name = item.name
        self.quantity = item.quantity
        self.category = item.category
        self.isStaple = item.isStaple
        self.dateAdded = item.dateAdded
        self.expiresAt = nil
    }
    
    /// Convert to local FridgeItem model
    func toFridgeItem() -> FridgeItem {
        FridgeItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            dateAdded: dateAdded,
            isStaple: isStaple
        )
    }
}

// MARK: - Pantry Item DTO
/// Maps to `pantry_items` table
struct PantryItemDTO: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    var ingredientId: UUID?
    var name: String
    var quantity: String
    var unit: String
    var category: String
    var isStaple: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ingredientId = "ingredient_id"
        case name
        case quantity
        case unit
        case category
        case isStaple = "is_staple"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        ingredientId = try container.decodeIfPresent(UUID.self, forKey: .ingredientId)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity) ?? ""
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "other"
        isStaple = try container.decodeIfPresent(Bool.self, forKey: .isStaple) ?? true
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    /// Convert from local Ingredient model
    init(from ingredient: Ingredient, userId: UUID) {
        self.id = ingredient.id
        self.userId = userId
        self.ingredientId = nil
        self.name = ingredient.name
        self.quantity = ingredient.quantity
        self.unit = ingredient.unit
        self.category = ingredient.category
        self.isStaple = ingredient.isStaple
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Convert to local Ingredient model
    func toIngredient() -> Ingredient {
        Ingredient(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
            isSelected: true,
            isStaple: isStaple
        )
    }
}

// MARK: - Recipe DTO
/// Maps to `recipes` table
struct RecipeDTO: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var title: String
    var description: String?
    var imagePath: String?
    var prepTime: Int
    var cookTime: Int
    var servings: Int
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var ingredients: [String]  // JSONB array
    var steps: [String]        // JSONB array
    var isPublic: Bool
    var isAiGenerated: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case imagePath = "image_path"
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case servings
        case calories
        case protein
        case carbs
        case fats
        case ingredients
        case steps
        case isPublic = "is_public"
        case isAiGenerated = "is_ai_generated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert from local Recipe model
    init(from recipe: Recipe, userId: UUID?, isAiGenerated: Bool = false) {
        self.id = recipe.id
        self.userId = userId
        self.title = recipe.title
        self.description = recipe.description
        self.imagePath = recipe.imageNamePlaceholder
        self.prepTime = recipe.prepTime
        self.cookTime = recipe.cookTime
        self.servings = 2  // Default
        self.calories = recipe.macros.calories
        self.protein = recipe.macros.protein
        self.carbs = recipe.macros.carbs
        self.fats = recipe.macros.fats
        self.ingredients = recipe.ingredients
        self.steps = recipe.steps
        self.isPublic = false
        self.isAiGenerated = isAiGenerated
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Convert to local Recipe model
    func toRecipe() -> Recipe {
        Recipe(
            id: id,
            title: title,
            description: description ?? "",
            imageNamePlaceholder: imagePath ?? "",
            ingredients: ingredients,
            steps: steps,
            prepTime: prepTime,
            cookTime: cookTime,
            macros: MacroNutrients(
                protein: protein,
                carbs: carbs,
                fats: fats,
                calories: calories
            )
        )
    }
}

// MARK: - Saved Recipe DTO
/// Maps to `saved_recipes` table (favorites)
struct SavedRecipeDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let recipeId: UUID
    var savedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeId = "recipe_id"
        case savedAt = "saved_at"
    }
}

// MARK: - Recipe History DTO
/// Maps to `recipe_history` table
struct RecipeHistoryDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let recipeId: UUID
    var cookedAt: Date
    var rating: Int?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeId = "recipe_id"
        case cookedAt = "cooked_at"
        case rating
        case notes
    }
}

// MARK: - Recipe Feedback DTO
/// Maps to `recipe_feedback` table
struct RecipeFeedbackDTO: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    let recipeId: UUID
    var recipeName: String
    var rating: Int
    var enjoyed: Bool?
    var comments: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeId = "recipe_id"
        case recipeName = "recipe_name"
        case rating
        case enjoyed
        case comments
        case createdAt = "created_at"
    }
    
    /// Convert from local RecipeFeedback model
    init(from feedback: RecipeFeedback, userId: UUID) {
        self.id = feedback.id
        self.userId = userId
        self.recipeId = feedback.recipeId
        self.recipeName = feedback.recipeName
        self.rating = feedback.rating
        self.enjoyed = feedback.enjoyed
        self.comments = feedback.comments.isEmpty ? nil : feedback.comments
        self.createdAt = feedback.timestamp
    }
    
    /// Convert to local RecipeFeedback model
    func toRecipeFeedback() -> RecipeFeedback {
        RecipeFeedback(
            id: id,
            recipeId: recipeId,
            recipeName: recipeName,
            rating: rating,
            enjoyed: enjoyed ?? true,
            comments: comments ?? "",
            timestamp: createdAt
        )
    }
}

// MARK: - Chat Session DTO
/// Maps to `chat_sessions` table
struct ChatSessionDTO: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    var recipeId: UUID?
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeId = "recipe_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert from local ChatSession model
    init(from session: ChatSession, userId: UUID) {
        self.id = session.id
        self.userId = userId
        self.recipeId = session.recipeId
        self.title = session.title
        self.createdAt = session.createdAt
        self.updatedAt = session.updatedAt
    }
    
    /// Convert to local ChatSession model (without messages - fetch separately)
    func toChatSession() -> ChatSession {
        ChatSession(
            id: id,
            title: title,
            messages: [],
            createdAt: createdAt,
            updatedAt: updatedAt,
            recipeId: recipeId
        )
    }
}

// MARK: - Chat Message DTO
/// Maps to `chat_messages` table
struct ChatMessageDTO: Codable, Identifiable {
    var id: UUID
    let sessionId: UUID
    let userId: UUID
    var contentType: String
    var content: String
    var recipeData: RecipeDTO?
    var isUser: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case contentType = "content_type"
        case content
        case recipeData = "recipe_data"
        case isUser = "is_user"
        case createdAt = "created_at"
    }
    
    /// Convert from local ChatMessage model
    init(from message: ChatMessage, sessionId: UUID, userId: UUID) {
        self.id = message.id
        self.sessionId = sessionId
        self.userId = userId
        self.isUser = message.isUser
        self.createdAt = message.timestamp
        
        switch message.content {
        case .text(let text):
            self.contentType = "text"
            self.content = text
            self.recipeData = nil
        case .recipeCard(let recipe):
            self.contentType = "recipe_card"
            self.content = recipe.title
            self.recipeData = RecipeDTO(from: recipe, userId: userId, isAiGenerated: true)
        }
    }
    
    /// Convert to local ChatMessage model
    func toChatMessage() -> ChatMessage {
        if contentType == "recipe_card", let recipeDTO = recipeData {
            return ChatMessage(
                id: id,
                content: .recipeCard(recipeDTO.toRecipe()),
                isUser: isUser,
                timestamp: createdAt
            )
        } else {
            return ChatMessage(
                id: id,
                content: .text(content),
                isUser: isUser,
                timestamp: createdAt
            )
        }
    }
}

// MARK: - Daily Macro Log DTO
/// Maps to `daily_macro_logs` table
struct DailyMacroLogDTO: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    var logDate: Date
    var caloriesConsumed: Int
    var proteinConsumed: Double
    var carbsConsumed: Double
    var fatsConsumed: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case logDate = "log_date"
        case caloriesConsumed = "calories_consumed"
        case proteinConsumed = "protein_consumed"
        case carbsConsumed = "carbs_consumed"
        case fatsConsumed = "fats_consumed"
    }
    
    /// Convert from local DailyMacroLog model
    init(from log: DailyMacroLog, id: UUID = UUID(), userId: UUID) {
        self.id = id
        self.userId = userId
        self.logDate = log.date
        self.caloriesConsumed = log.caloriesConsumed
        self.proteinConsumed = log.proteinConsumed
        self.carbsConsumed = log.carbsConsumed
        self.fatsConsumed = log.fatsConsumed
    }
    
    /// Convert to local DailyMacroLog model
    func toDailyMacroLog() -> DailyMacroLog {
        var log = DailyMacroLog()
        log.date = logDate
        log.caloriesConsumed = caloriesConsumed
        log.proteinConsumed = proteinConsumed
        log.carbsConsumed = carbsConsumed
        log.fatsConsumed = fatsConsumed
        return log
    }
}

// MARK: - Activity Feed DTO
/// Maps to `activity_feed` table
struct ActivityFeedDTO: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    var activityType: String
    var title: String
    var relatedId: UUID?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case title
        case relatedId = "related_id"
        case createdAt = "created_at"
    }
    
    /// Convert from local ActivityItem model
    init(from activity: ActivityItem, userId: UUID) {
        self.id = activity.id
        self.userId = userId
        self.activityType = activity.type.rawValue
        self.title = activity.title
        self.relatedId = activity.relatedId
        self.createdAt = activity.timestamp
    }
    
    /// Convert to local ActivityItem model
    func toActivityItem() -> ActivityItem? {
        guard let type = ActivityItem.ActivityType(rawValue: activityType) else {
            return nil
        }
        return ActivityItem(
            id: id,
            type: type,
            title: title,
            timestamp: createdAt,
            relatedId: relatedId
        )
    }
}

// MARK: - Insert DTOs (for creating new records without id)

/// DTO for inserting new fridge items
struct FridgeItemInsertDTO: Codable {
    let userId: UUID
    var name: String
    var quantity: String
    var category: String
    var isStaple: Bool
    var dateAdded: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case quantity
        case category
        case isStaple = "is_staple"
        case dateAdded = "date_added"
    }
    
    init(from item: FridgeItem, userId: UUID) {
        self.userId = userId
        self.name = item.name
        self.quantity = item.quantity
        self.category = item.category
        self.isStaple = item.isStaple
        self.dateAdded = item.dateAdded
    }
}

/// DTO for inserting new pantry items
struct PantryItemInsertDTO: Codable {
    let userId: UUID
    var name: String
    var quantity: String
    var unit: String
    var isStaple: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case quantity
        case unit
        case isStaple = "is_staple"
    }
    
    init(from ingredient: Ingredient, userId: UUID) {
        self.userId = userId
        self.name = ingredient.name
        self.quantity = ingredient.quantity
        self.unit = ingredient.unit
        self.isStaple = ingredient.isStaple
    }
}

/// DTO for inserting saved recipes (favorites)
struct SavedRecipeInsertDTO: Codable {
    let userId: UUID
    let recipeId: UUID
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recipeId = "recipe_id"
    }
}

/// DTO for inserting chat sessions
struct ChatSessionInsertDTO: Codable {
    let userId: UUID
    var recipeId: UUID?
    var title: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recipeId = "recipe_id"
        case title
    }
}

/// DTO for inserting chat messages
struct ChatMessageInsertDTO: Codable {
    let sessionId: UUID
    let userId: UUID
    var contentType: String
    var content: String
    var recipeData: RecipeDTO?
    var isUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case userId = "user_id"
        case contentType = "content_type"
        case content
        case recipeData = "recipe_data"
        case isUser = "is_user"
    }
}

/// DTO for inserting activity feed items
struct ActivityFeedInsertDTO: Codable {
    let userId: UUID
    var activityType: String
    var title: String
    var relatedId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activityType = "activity_type"
        case title
        case relatedId = "related_id"
    }
}

// MARK: - Update DTOs (for partial updates)

/// DTO for updating user preferences
struct UserPreferencesUpdateDTO: Codable {
    var dietaryPreferences: [String]?
    var allergies: [String]?
    var dailyCalories: Int?
    var proteinPercentage: Double?
    var carbsPercentage: Double?
    var fatsPercentage: Double?
    var hasMacroGoals: Bool?
    
    enum CodingKeys: String, CodingKey {
        case dietaryPreferences = "dietary_preferences"
        case allergies
        case dailyCalories = "daily_calories"
        case proteinPercentage = "protein_percentage"
        case carbsPercentage = "carbs_percentage"
        case fatsPercentage = "fats_percentage"
        case hasMacroGoals = "has_macro_goals"
    }
}

/// DTO for updating profile
struct ProfileUpdateDTO: Codable {
    var name: String?
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case avatarUrl = "avatar_url"
    }
}
