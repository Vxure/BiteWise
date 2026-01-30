//
//  SupabaseDataService.swift
//  BiteWise
//
//  Service layer for Supabase database operations.
//  Provides async CRUD methods for all data entities.
//

import Foundation
import Supabase
import Functions

// MARK: - Data Service Errors

enum DataServiceError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .userNotFound:
            return "User profile not found."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

// MARK: - Supabase Data Service

@MainActor
final class SupabaseDataService {
    
    static let shared = SupabaseDataService()
    
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Get the current authenticated user's ID
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try? await supabase.auth.session.user else {
            throw DataServiceError.notAuthenticated
        }
        return user.id
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        get async {
            do {
                _ = try await supabase.auth.session
                return true
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Profile & Preferences
    
    /// Fetch the current user's profile
    func fetchProfile() async throws -> ProfileDTO {
        let userId = try await getCurrentUserId()
        
        let profile: ProfileDTO = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    /// Update the current user's profile
    func updateProfile(_ update: ProfileUpdateDTO) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }
    
    /// Fetch the current user's preferences
    func fetchUserPreferences() async throws -> UserPreferencesDTO {
        let userId = try await getCurrentUserId()
        
        let preferences: UserPreferencesDTO = try await supabase
            .from("user_preferences")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return preferences
    }
    
    /// Update the current user's preferences
    func updateUserPreferences(_ update: UserPreferencesUpdateDTO) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("user_preferences")
            .update(update)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Fetch combined user profile data (profile + preferences)
    func fetchFullUserProfile() async throws -> (profile: ProfileDTO, preferences: UserPreferencesDTO) {
        async let profile = fetchProfile()
        async let preferences = fetchUserPreferences()
        
        return try await (profile, preferences)
    }
    
    // MARK: - Fridge Items
    
    /// Fetch all fridge items for the current user
    func fetchFridgeItems() async throws -> [FridgeItemDTO] {
        let userId = try await getCurrentUserId()
        
        let items: [FridgeItemDTO] = try await supabase
            .from("fridge_items")
            .select()
            .eq("user_id", value: userId)
            .order("date_added", ascending: false)
            .execute()
            .value
        
        return items
    }
    
    /// Add a fridge item
    func addFridgeItem(_ item: FridgeItem) async throws -> FridgeItemDTO {
        let userId = try await getCurrentUserId()
        let dto = FridgeItemDTO(from: item, userId: userId)
        
        let inserted: FridgeItemDTO = try await supabase
            .from("fridge_items")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value
        
        return inserted
    }
    
    /// Add multiple fridge items at once
    func addFridgeItems(_ items: [FridgeItem]) async throws -> [FridgeItemDTO] {
        let userId = try await getCurrentUserId()
        let dtos = items.map { FridgeItemDTO(from: $0, userId: userId) }
        
        let inserted: [FridgeItemDTO] = try await supabase
            .from("fridge_items")
            .insert(dtos)
            .select()
            .execute()
            .value
        
        return inserted
    }
    
    /// Delete a fridge item by ID
    func deleteFridgeItem(_ itemId: UUID) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("fridge_items")
            .delete()
            .eq("id", value: itemId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Delete all fridge items for the current user
    func deleteAllFridgeItems() async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("fridge_items")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Replace all fridge items (delete existing, insert new)
    func replaceFridgeItems(with items: [FridgeItem]) async throws -> [FridgeItemDTO] {
        try await deleteAllFridgeItems()
        return try await addFridgeItems(items)
    }
    
    // MARK: - Pantry Items
    
    /// Fetch all pantry items for the current user
    func fetchPantryItems() async throws -> [PantryItemDTO] {
        let userId = try await getCurrentUserId()
        
        let items: [PantryItemDTO] = try await supabase
            .from("pantry_items")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return items
    }
    
    /// Add a pantry item
    func addPantryItem(_ item: Ingredient) async throws -> PantryItemDTO {
        let userId = try await getCurrentUserId()
        let dto = PantryItemDTO(from: item, userId: userId)
        
        let inserted: PantryItemDTO = try await supabase
            .from("pantry_items")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value
        
        return inserted
    }
    
    /// Delete a pantry item by ID
    func deletePantryItem(_ itemId: UUID) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("pantry_items")
            .delete()
            .eq("id", value: itemId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Delete all pantry items for the current user
    func deleteAllPantryItems() async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("pantry_items")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Recipes
    
    /// Fetch a recipe by ID
    func fetchRecipe(_ recipeId: UUID) async throws -> RecipeDTO? {
        let recipe: RecipeDTO? = try await supabase
            .from("recipes")
            .select()
            .eq("id", value: recipeId)
            .single()
            .execute()
            .value
        
        return recipe
    }
    
    /// Save a recipe (create if not exists, update if exists)
    func saveRecipe(_ recipe: Recipe, isAiGenerated: Bool = false) async throws -> RecipeDTO {
        let userId = try await getCurrentUserId()
        let dto = RecipeDTO(from: recipe, userId: userId, isAiGenerated: isAiGenerated)
        
        let saved: RecipeDTO = try await supabase
            .from("recipes")
            .upsert(dto)
            .select()
            .single()
            .execute()
            .value
        
        return saved
    }
    
    /// Delete a recipe by ID
    func deleteRecipe(_ recipeId: UUID) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("recipes")
            .delete()
            .eq("id", value: recipeId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Saved Recipes (Favorites)
    
    /// Fetch all saved/favorited recipes for the current user
    func fetchSavedRecipes() async throws -> [RecipeDTO] {
        let userId = try await getCurrentUserId()
        
        // First get the saved recipe references
        let savedRefs: [SavedRecipeDTO] = try await supabase
            .from("saved_recipes")
            .select()
            .eq("user_id", value: userId)
            .order("saved_at", ascending: false)
            .execute()
            .value
        
        // Then fetch the actual recipes
        let recipeIds = savedRefs.map { $0.recipeId }
        guard !recipeIds.isEmpty else { return [] }
        
        let recipes: [RecipeDTO] = try await supabase
            .from("recipes")
            .select()
            .in("id", values: recipeIds)
            .execute()
            .value
        
        return recipes
    }
    
    /// Save a recipe as favorite
    func saveRecipeAsFavorite(_ recipe: Recipe) async throws {
        let userId = try await getCurrentUserId()
        
        // First ensure the recipe exists in the database
        _ = try await saveRecipe(recipe)
        
        // Then add to saved_recipes
        let insertDTO = SavedRecipeInsertDTO(userId: userId, recipeId: recipe.id)
        
        try await supabase
            .from("saved_recipes")
            .upsert(insertDTO)
            .execute()
    }
    
    /// Remove a recipe from favorites
    func removeRecipeFromFavorites(_ recipeId: UUID) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("saved_recipes")
            .delete()
            .eq("user_id", value: userId)
            .eq("recipe_id", value: recipeId)
            .execute()
    }
    
    /// Check if a recipe is favorited
    func isRecipeFavorited(_ recipeId: UUID) async throws -> Bool {
        let userId = try await getCurrentUserId()
        
        let results: [SavedRecipeDTO] = try await supabase
            .from("saved_recipes")
            .select()
            .eq("user_id", value: userId)
            .eq("recipe_id", value: recipeId)
            .execute()
            .value
        
        return !results.isEmpty
    }
    
    // MARK: - Recipe History
    
    /// Fetch recipe history (cooked recipes) for the current user
    func fetchRecipeHistory() async throws -> [RecipeHistoryDTO] {
        let userId = try await getCurrentUserId()
        
        let history: [RecipeHistoryDTO] = try await supabase
            .from("recipe_history")
            .select()
            .eq("user_id", value: userId)
            .order("cooked_at", ascending: false)
            .execute()
            .value
        
        return history
    }
    
    /// Log a recipe as cooked
    func logCookedRecipe(_ recipe: Recipe, rating: Int? = nil) async throws {
        let userId = try await getCurrentUserId()
        
        // Ensure recipe exists
        _ = try await saveRecipe(recipe)
        
        // Create history entry
        let historyDTO = RecipeHistoryDTO(
            id: UUID(),
            userId: userId,
            recipeId: recipe.id,
            cookedAt: Date(),
            rating: rating,
            notes: nil
        )
        
        try await supabase
            .from("recipe_history")
            .insert(historyDTO)
            .execute()
    }
    
    // MARK: - Recipe Feedback
    
    /// Fetch all feedback for the current user
    func fetchRecipeFeedback() async throws -> [RecipeFeedbackDTO] {
        let userId = try await getCurrentUserId()
        
        let feedback: [RecipeFeedbackDTO] = try await supabase
            .from("recipe_feedback")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return feedback
    }
    
    /// Save recipe feedback
    func saveRecipeFeedback(_ feedback: RecipeFeedback) async throws {
        let userId = try await getCurrentUserId()
        let dto = RecipeFeedbackDTO(from: feedback, userId: userId)
        
        try await supabase
            .from("recipe_feedback")
            .upsert(dto)
            .execute()
    }
    
    // MARK: - Chat Sessions
    
    /// Fetch all chat sessions for the current user
    func fetchChatSessions() async throws -> [ChatSessionDTO] {
        let userId = try await getCurrentUserId()
        
        let sessions: [ChatSessionDTO] = try await supabase
            .from("chat_sessions")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .execute()
            .value
        
        return sessions
    }
    
    /// Create a new chat session
    func createChatSession(title: String, recipeId: UUID? = nil) async throws -> ChatSessionDTO {
        let userId = try await getCurrentUserId()
        
        let insertDTO = ChatSessionInsertDTO(userId: userId, recipeId: recipeId, title: title)
        
        let session: ChatSessionDTO = try await supabase
            .from("chat_sessions")
            .insert(insertDTO)
            .select()
            .single()
            .execute()
            .value
        
        return session
    }
    
    /// Update a chat session's title
    func updateChatSessionTitle(_ sessionId: UUID, title: String) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("chat_sessions")
            .update(["title": title])
            .eq("id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Delete a chat session
    func deleteChatSession(_ sessionId: UUID) async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("chat_sessions")
            .delete()
            .eq("id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Delete all chat sessions for the current user
    func deleteAllChatSessions() async throws {
        let userId = try await getCurrentUserId()
        
        try await supabase
            .from("chat_sessions")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Chat Messages
    
    /// Fetch messages for a specific chat session
    func fetchChatMessages(forSession sessionId: UUID) async throws -> [ChatMessageDTO] {
        let userId = try await getCurrentUserId()
        
        let messages: [ChatMessageDTO] = try await supabase
            .from("chat_messages")
            .select()
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return messages
    }
    
    /// Add a message to a chat session
    func addChatMessage(_ message: ChatMessage, toSession sessionId: UUID) async throws -> ChatMessageDTO {
        let userId = try await getCurrentUserId()
        let dto = ChatMessageDTO(from: message, sessionId: sessionId, userId: userId)
        
        let inserted: ChatMessageDTO = try await supabase
            .from("chat_messages")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value
        
        return inserted
    }
    
    // MARK: - Daily Macro Logs
    
    /// Fetch today's macro log
    func fetchTodaysMacroLog() async throws -> DailyMacroLogDTO? {
        let userId = try await getCurrentUserId()
        let today = Calendar.current.startOfDay(for: Date())
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let todayString = formatter.string(from: today)
        
        let logs: [DailyMacroLogDTO] = try await supabase
            .from("daily_macro_logs")
            .select()
            .eq("user_id", value: userId)
            .eq("log_date", value: todayString)
            .execute()
            .value
        
        return logs.first
    }
    
    /// Fetch macro logs for a date range
    func fetchMacroLogs(from startDate: Date, to endDate: Date) async throws -> [DailyMacroLogDTO] {
        let userId = try await getCurrentUserId()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        let logs: [DailyMacroLogDTO] = try await supabase
            .from("daily_macro_logs")
            .select()
            .eq("user_id", value: userId)
            .gte("log_date", value: formatter.string(from: startDate))
            .lte("log_date", value: formatter.string(from: endDate))
            .order("log_date", ascending: false)
            .execute()
            .value
        
        return logs
    }
    
    /// Update or create today's macro log
    func updateDailyMacros(_ log: DailyMacroLog) async throws {
        let userId = try await getCurrentUserId()
        
        // Check if log exists for today
        if let existing = try await fetchTodaysMacroLog() {
            // Update existing
            let update = DailyMacroLogDTO(from: log, id: existing.id, userId: userId)
            try await supabase
                .from("daily_macro_logs")
                .update(update)
                .eq("id", value: existing.id)
                .execute()
        } else {
            // Insert new
            let insert = DailyMacroLogDTO(from: log, userId: userId)
            try await supabase
                .from("daily_macro_logs")
                .insert(insert)
                .execute()
        }
    }
    
    // MARK: - Activity Feed
    
    /// Fetch recent activity for the current user
    func fetchActivityFeed(limit: Int = 50) async throws -> [ActivityFeedDTO] {
        let userId = try await getCurrentUserId()
        
        let activities: [ActivityFeedDTO] = try await supabase
            .from("activity_feed")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return activities
    }
    
    /// Log an activity
    func logActivity(_ activity: ActivityItem) async throws {
        let userId = try await getCurrentUserId()
        
        let insertDTO = ActivityFeedInsertDTO(
            userId: userId,
            activityType: activity.type.rawValue,
            title: activity.title,
            relatedId: activity.relatedId
        )
        
        try await supabase
            .from("activity_feed")
            .insert(insertDTO)
            .execute()
    }
    
    // MARK: - Account Deletion
    
    /// Response structure for deletion job
    struct DeletionJobResponse: Decodable {
        let success: Bool
        let jobId: String?
        let status: String?
        let message: String?
        
        enum CodingKeys: String, CodingKey {
            case success
            case jobId = "job_id"
            case status
            case message
        }
    }
    
    /// Delete all user data from the database
    /// This triggers the job-based deletion flow for robustness
    /// - Returns: The deletion job status
    @discardableResult
    func deleteAllUserData() async throws -> DeletionJobResponse {
        // Ensure the user is authenticated
        _ = try await getCurrentUserId()
        
        // Call the server-side deletion function (Edge Function)
        // This creates a job and processes it immediately
        // Use decode option to get the response as our expected type
        do {
            let jobResponse: DeletionJobResponse = try await supabase.functions.invoke(
                "delete-user-account",
                options: FunctionInvokeOptions(
                    body: [:] as [String: String] // Empty body
                )
            )
            
            // Check for errors in the response
            if !jobResponse.success {
                throw DataServiceError.serverError(jobResponse.message ?? "Deletion failed")
            }
            
            return jobResponse
        } catch let error as DataServiceError {
            throw error
        } catch {
            throw DataServiceError.serverError("Failed to delete account: \(error.localizedDescription)")
        }
    }
    
    /// Check the status of a deletion job
    /// - Returns: The current job status
    func getDeletionJobStatus() async throws -> DeletionJobResponse {
        _ = try await getCurrentUserId()
        
        // Call the RPC and decode the JSON response
        let jsonData: Data = try await supabase.rpc("get_deletion_job_status").execute().data
        
        // Parse the JSON manually since the RPC returns a JSON object
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw DataServiceError.decodingError(NSError(domain: "SupabaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"]))
        }
        
        return DeletionJobResponse(
            success: json["success"] as? Bool ?? false,
            jobId: json["job_id"] as? String,
            status: json["status"] as? String,
            message: json["message"] as? String
        )
    }
    
    // MARK: - Bulk Sync Operations
    
    /// Sync all local data to the cloud
    /// Call this after authentication to push local data
    func syncAllDataToCloud(
        profile: UserProfile,
        fridgeItems: [FridgeItem],
        pantryItems: [Ingredient],
        favoriteRecipes: [Recipe],
        chatSessions: [ChatSession],
        dailyMacros: DailyMacroLog,
        activityLog: [ActivityItem]
    ) async throws {
        // Sync profile/preferences
        let preferencesUpdate = UserPreferencesUpdateDTO(
            dietaryPreferences: profile.dietaryPreferences,
            allergies: profile.allergies,
            dailyCalories: profile.macroGoals.dailyCalories,
            proteinPercentage: profile.macroGoals.proteinPercentage,
            carbsPercentage: profile.macroGoals.carbsPercentage,
            fatsPercentage: profile.macroGoals.fatsPercentage,
            hasMacroGoals: profile.hasMacroGoals
        )
        try await updateUserPreferences(preferencesUpdate)
        
        let profileUpdate = ProfileUpdateDTO(name: profile.name)
        try await updateProfile(profileUpdate)
        
        // Sync fridge items
        if !fridgeItems.isEmpty {
            _ = try await replaceFridgeItems(with: fridgeItems)
        }
        
        // Sync pantry items (delete and re-add)
        if !pantryItems.isEmpty {
            try await deleteAllPantryItems()
            for item in pantryItems {
                _ = try await addPantryItem(item)
            }
        }
        
        // Sync favorites
        for recipe in favoriteRecipes {
            try await saveRecipeAsFavorite(recipe)
        }
        
        // Sync daily macros
        if dailyMacros.caloriesConsumed > 0 {
            try await updateDailyMacros(dailyMacros)
        }
        
        // Note: Chat sessions and activity log are typically not bulk-synced
        // They grow incrementally and are synced per-operation
    }
    
    /// Load all data from cloud to local
    /// Call this after authentication to pull cloud data
    func loadAllDataFromCloud() async throws -> (
        profile: ProfileDTO?,
        preferences: UserPreferencesDTO?,
        fridgeItems: [FridgeItemDTO],
        pantryItems: [PantryItemDTO],
        favoriteRecipes: [RecipeDTO],
        chatSessions: [ChatSessionDTO],
        macroLog: DailyMacroLogDTO?,
        activityFeed: [ActivityFeedDTO]
    ) {
        async let profile = try? fetchProfile()
        async let preferences = try? fetchUserPreferences()
        async let fridge = (try? fetchFridgeItems()) ?? []
        async let pantry = (try? fetchPantryItems()) ?? []
        async let favorites = (try? fetchSavedRecipes()) ?? []
        async let sessions = (try? fetchChatSessions()) ?? []
        async let macros = try? fetchTodaysMacroLog()
        async let activities = (try? fetchActivityFeed()) ?? []
        
        return await (
            profile,
            preferences,
            fridge,
            pantry,
            favorites,
            sessions,
            macros,
            activities
        )
    }
}
