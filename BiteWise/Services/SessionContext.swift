import Foundation
import SwiftUI

/// Detected ingredient from Gemini Vision API
struct DetectedIngredient: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var quantity: String
    var category: String
    
    /// Convert to the existing IngredientItem format used by DetectedIngredientsScreen
    func toIngredientItem() -> IngredientItem {
        IngredientItem(
            name: name,
            isSelected: true,
            isAIDetected: true
        )
    }
}

// MARK: - Dummy Data for Demo Mode
extension DetectedIngredient {
    static var dummyData: [DetectedIngredient] = [
        DetectedIngredient(name: "Chicken Breast", quantity: "2 pieces", category: "protein"),
        DetectedIngredient(name: "Eggs", quantity: "6", category: "protein"),
        DetectedIngredient(name: "Fresh Spinach", quantity: "1 bunch", category: "vegetable"),
        DetectedIngredient(name: "Shredded Cheese", quantity: "1 cup", category: "dairy"),
        DetectedIngredient(name: "Milk", quantity: "1 carton", category: "dairy"),
        DetectedIngredient(name: "Butter", quantity: "1 stick", category: "dairy"),
        DetectedIngredient(name: "Tomatoes", quantity: "4", category: "vegetable")
    ]
}

/// Session context that holds state shared across screens during a user session
/// This enables the chatbot to know about detected ingredients and generated recipes
class SessionContext: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SessionContext()
    
    // MARK: - Published State
    
    /// Ingredients detected from the fridge photo
    @Published var detectedIngredients: [DetectedIngredient] = []
    
    /// Recipes generated based on detected ingredients
    @Published var generatedRecipes: [Recipe] = []
    
    /// The image that was analyzed (for display purposes)
    @Published var analyzedImage: UIImage?
    
    /// Per-recipe conversation histories (keyed by recipe ID)
    /// Each recipe maintains its own chat history
    @Published var recipeChatHistories: [UUID: [ChatMessage]] = [:]
    
    /// General chat history for non-recipe-specific assistant usage
    @Published var generalChatHistory: [ChatMessage] = []
    
    /// Currently selected ingredients (after user confirms/modifies)
    @Published var selectedIngredientNames: [String] = []
    
    /// The recipe currently being discussed in chat (if any)
    @Published var currentRecipeContext: Recipe?
    
    /// The currently active chat session (for multi-conversation support)
    @Published var activeChatSession: ChatSession?
    
    // MARK: - Initialization
    
    private init() {
        // Load persisted chat histories from DataManager
        generalChatHistory = DataManager.shared.generalChatHistory
        recipeChatHistories = DataManager.shared.recipeChatHistories
    }
    
    // MARK: - Session Management
    
    /// Start a new session (clears session-specific data but preserves chat histories)
    /// Called when user uploads a new photo
    func startNewSession() {
        detectedIngredients = []
        generatedRecipes = []
        analyzedImage = nil
        selectedIngredientNames = []
        currentRecipeContext = nil
        // Note: Chat histories are persisted and not cleared on new session
        // This allows users to reference past conversations
    }
    
    /// Clear all session data including chat histories (for full reset)
    func clearAllSessionData() {
        detectedIngredients = []
        generatedRecipes = []
        analyzedImage = nil
        recipeChatHistories = [:]
        generalChatHistory = []
        selectedIngredientNames = []
        currentRecipeContext = nil
        
        // Also clear persisted chat histories
        DataManager.shared.clearAllChatHistories()
    }
    
    /// Update selected ingredients from the DetectedIngredientsScreen
    func updateSelectedIngredients(_ names: [String]) {
        selectedIngredientNames = names
    }
    
    // MARK: - Per-Recipe Chat History Management
    
    /// Get chat history for a specific recipe
    /// - Parameter recipeId: The UUID of the recipe
    /// - Returns: Array of chat messages for that recipe, or empty array if none
    func getChatHistory(for recipeId: UUID) -> [ChatMessage] {
        return recipeChatHistories[recipeId] ?? []
    }
    
    /// Update chat history for a specific recipe and persist to DataManager
    /// - Parameters:
    ///   - recipeId: The UUID of the recipe
    ///   - messages: The updated chat messages
    func updateChatHistory(for recipeId: UUID, messages: [ChatMessage]) {
        recipeChatHistories[recipeId] = messages
        // Persist to DataManager
        DataManager.shared.updateChatHistory(for: recipeId, messages: messages)
    }
    
    /// Update general chat history and persist to DataManager
    func updateGeneralChatHistory(_ messages: [ChatMessage]) {
        generalChatHistory = messages
        // Persist to DataManager
        DataManager.shared.generalChatHistory = messages
        DataManager.shared.saveGeneralChatHistory()
    }
    
    /// Add a message to the general chat and persist
    func addGeneralChatMessage(_ message: ChatMessage) {
        generalChatHistory.append(message)
        DataManager.shared.addGeneralChatMessage(message)
    }
    
    /// Add a message to a recipe's chat and persist
    func addRecipeChatMessage(_ message: ChatMessage, for recipeId: UUID) {
        if recipeChatHistories[recipeId] == nil {
            recipeChatHistories[recipeId] = []
        }
        recipeChatHistories[recipeId]?.append(message)
        DataManager.shared.addRecipeChatMessage(message, for: recipeId)
    }
    
    /// Set the current recipe being discussed
    func setCurrentRecipe(_ recipe: Recipe?) {
        currentRecipeContext = recipe
    }
    
    // MARK: - Chat Session Management (Multi-conversation support)
    
    /// Start a new chat session and set it as active
    /// - Parameters:
    ///   - title: Initial title (defaults to "New Chat")
    ///   - recipeId: Optional recipe ID for recipe-specific chats
    /// - Returns: The newly created chat session
    @discardableResult
    func startNewChatSession(title: String = "New Chat", recipeId: UUID? = nil) -> ChatSession {
        let session = DataManager.shared.createChatSession(title: title, recipeId: recipeId)
        activeChatSession = session
        return session
    }
    
    /// Load an existing chat session and set it as active
    /// - Parameter sessionId: The ID of the session to load
    func loadChatSession(_ sessionId: UUID) {
        if let session = DataManager.shared.getChatSession(sessionId) {
            activeChatSession = session
            // Also set recipe context if this is a recipe-specific chat
            if let recipeId = session.recipeId {
                // Try to find the recipe in generated recipes or history
                currentRecipeContext = generatedRecipes.first { $0.id == recipeId }
                    ?? DataManager.shared.recipeHistory.first { $0.id == recipeId }
            } else {
                currentRecipeContext = nil
            }
        }
    }
    
    /// Add a message to the active chat session
    /// - Parameter message: The message to add
    func addMessageToActiveSession(_ message: ChatMessage) {
        guard var session = activeChatSession else { return }
        session.addMessage(message)
        activeChatSession = session
        DataManager.shared.updateChatSession(session)
    }
    
    /// Clear the active chat session (return to landing state)
    func clearActiveChatSession() {
        activeChatSession = nil
        currentRecipeContext = nil
    }
    
    /// Check if there's an active chat session
    var hasActiveChatSession: Bool {
        activeChatSession != nil
    }
    
    /// Get all available chat sessions (sorted by most recent)
    var allChatSessions: [ChatSession] {
        DataManager.shared.chatSessions
    }
    
    /// Get general (non-recipe) chat sessions
    var generalSessions: [ChatSession] {
        DataManager.shared.generalChatSessions
    }
    
    /// Delete a chat session
    /// - Parameter sessionId: The ID of the session to delete
    func deleteChatSession(_ sessionId: UUID) {
        // If deleting the active session, clear it
        if activeChatSession?.id == sessionId {
            activeChatSession = nil
        }
        DataManager.shared.deleteChatSession(sessionId)
    }
    
    // MARK: - Context Building for Chatbot
    
    /// Build a context string that gives the chatbot full awareness of the session
    /// This includes detected ingredients, generated recipes, and user preferences
    /// Optimized for minimal token usage while retaining essential context
    func buildChatContext(userProfile: UserProfile) -> String {
        let dataManager = DataManager.shared
        var parts: [String] = []
        
        // Core identity (minimal)
        parts.append("BiteWise cooking assistant. Help with recipes, cooking tips, substitutions.")
        
        // User profile (compact format)
        var userParts: [String] = []
        if !userProfile.name.isEmpty { userParts.append("Name: \(userProfile.name)") }
        if !userProfile.allergies.isEmpty { userParts.append("ALLERGIES (avoid): \(userProfile.allergies.joined(separator: ", "))") }
        if !userProfile.dietaryPreferences.isEmpty { userParts.append("Prefs: \(userProfile.dietaryPreferences.joined(separator: ", "))") }
        
        // Macro goals (compact)
        if userProfile.hasMacroGoals {
            let cal = userProfile.macroGoals.dailyCalories
            let proteinG = Int((Double(cal) * userProfile.macroGoals.proteinPercentage / 100) / 4)
            userParts.append("Goals: \(cal)cal/\(proteinG)gP daily")
        }
        
        if !userParts.isEmpty {
            parts.append("USER: " + userParts.joined(separator: " | "))
        }
        
        // Today's consumption (only if tracking)
        let todayMacros = dataManager.dailyMacros
        if todayMacros.caloriesConsumed > 0 {
            let goals = dataManager.macroGoalsInGrams
            let calRemaining = max(0, goals.calories - todayMacros.caloriesConsumed)
            parts.append("TODAY: \(todayMacros.caloriesConsumed)cal consumed, ~\(calRemaining)cal remaining")
        }
        
        // Available ingredients (prioritized: selected > detected > fridge)
        if !selectedIngredientNames.isEmpty {
            parts.append("INGREDIENTS: \(selectedIngredientNames.joined(separator: ", "))")
        } else if !detectedIngredients.isEmpty {
            parts.append("INGREDIENTS: \(detectedIngredients.map { $0.name }.joined(separator: ", "))")
        } else if dataManager.hasFridgeItems {
            let items = dataManager.fridgeItems.prefix(15).map { $0.name }.joined(separator: ", ")
            parts.append("FRIDGE: \(items)")
        }
        
        // Pantry (compact)
        if !dataManager.pantryItems.isEmpty {
            let pantry = dataManager.pantryItems.prefix(10).map { $0.name }.joined(separator: ", ")
            parts.append("PANTRY: \(pantry)")
        }
        
        // Favorites (just names, limited)
        if dataManager.hasFavorites {
            let favs = dataManager.favoriteRecipes.prefix(3).map { $0.title }.joined(separator: ", ")
            parts.append("FAVORITES: \(favs)")
        }
        
        // Feedback (only low-rated, compact)
        let lowRated = dataManager.recipeFeedback.suffix(5).filter { $0.rating <= 2 }
        if !lowRated.isEmpty {
            let avoid = lowRated.map { $0.recipeName }.joined(separator: ", ")
            parts.append("AVOID (disliked): \(avoid)")
        }
        
        // Current recipe context (essential info only)
        if let recipe = currentRecipeContext {
            parts.append("""
            CURRENT RECIPE: \(recipe.title)
            Ingredients: \(recipe.ingredients.joined(separator: ", "))
            \(recipe.macros.calories)cal | \(Int(recipe.macros.protein))gP
            """)
        }
        
        // Suggested recipes (just titles)
        if !generatedRecipes.isEmpty {
            let titles = generatedRecipes.map { $0.title }.joined(separator: ", ")
            parts.append("SUGGESTED: \(titles)")
        }
        
        // Instructions (minimal)
        parts.append("""
        RULES: Be concise. Respect allergies. Use available ingredients.
        
        RECIPE GENERATION: When user wants a recipe, include [GENERATE_RECIPE: description] marker.
        Examples: [GENERATE_RECIPE: quick dinner under 30min] or [GENERATE_RECIPE: dairy-free version]
        Add brief intro text before/after marker. Marker is auto-removed from display.
        """)
        
        return parts.joined(separator: "\n\n")
    }
    
    // MARK: - Convenience Methods
    
    /// Check if we have ingredients to work with
    var hasIngredients: Bool {
        !detectedIngredients.isEmpty || !selectedIngredientNames.isEmpty
    }
    
    /// Check if we have recipes generated
    var hasRecipes: Bool {
        !generatedRecipes.isEmpty
    }
    
    /// Get ingredient names for recipe generation
    var ingredientNamesForRecipes: [String] {
        if !selectedIngredientNames.isEmpty {
            return selectedIngredientNames
        }
        return detectedIngredients.map { $0.name }
    }
}

