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
    func buildChatContext(userProfile: UserProfile) -> String {
        // Concise macro info based on whether user has set goals (using grams for actionable targets)
        let macroText: String
        if userProfile.hasMacroGoals {
            let cal = userProfile.macroGoals.dailyCalories
            let proteinG = Int((Double(cal) * userProfile.macroGoals.proteinPercentage / 100) / 4)
            let carbsG = Int((Double(cal) * userProfile.macroGoals.carbsPercentage / 100) / 4)
            let fatsG = Int((Double(cal) * userProfile.macroGoals.fatsPercentage / 100) / 9)
            macroText = "\(cal)cal/\(proteinG)gP/\(carbsG)gC/\(fatsG)gF daily"
        } else {
            macroText = "No specific goals"
        }
        
        var context = """
        You are a helpful cooking assistant for the BiteWise app. You help users with recipes, cooking tips, and ingredient substitutions.
        
        USER PROFILE:
        - Name: \(userProfile.name)
        - Dietary Preferences: \(userProfile.dietaryPreferences.joined(separator: ", "))
        - Allergies: \(userProfile.allergies.joined(separator: ", "))
        - Macros: \(macroText)
        
        """
        
        // Add today's consumed macros if user has been tracking
        let dataManager = DataManager.shared
        let todayMacros = dataManager.dailyMacros
        let goals = dataManager.macroGoalsInGrams
        
        if todayMacros.caloriesConsumed > 0 {
            let calRemaining = max(0, goals.calories - todayMacros.caloriesConsumed)
            let proteinRemaining = max(0, goals.protein - Int(todayMacros.proteinConsumed))
            let carbsRemaining = max(0, goals.carbs - Int(todayMacros.carbsConsumed))
            let fatsRemaining = max(0, goals.fats - Int(todayMacros.fatsConsumed))
            
            context += """
            
            TODAY'S CONSUMPTION:
            - Consumed: \(todayMacros.caloriesConsumed) cal, \(Int(todayMacros.proteinConsumed))g protein, \(Int(todayMacros.carbsConsumed))g carbs, \(Int(todayMacros.fatsConsumed))g fat
            - Remaining: ~\(calRemaining) cal, ~\(proteinRemaining)g protein, ~\(carbsRemaining)g carbs, ~\(fatsRemaining)g fat
            - Consider suggesting lighter meals if close to daily limit.
            
            """
        }
        
        // Add favorite recipes for personalization
        if dataManager.hasFavorites {
            let favoriteNames = dataManager.favoriteRecipes.prefix(5).map { $0.title }
            context += """
            
            USER'S FAVORITE RECIPES:
            \(favoriteNames.map { "- \($0)" }.joined(separator: "\n"))
            Consider suggesting variations of these or similar cuisines.
            
            """
        }
        
        // Add recent feedback for learning (focus on low-rated recipes to avoid)
        let recentFeedback = dataManager.recipeFeedback.suffix(10)
        let lowRated = recentFeedback.filter { $0.rating <= 2 }
        let highRated = recentFeedback.filter { $0.rating >= 4 }
        
        if !lowRated.isEmpty {
            context += """
            
            RECIPES USER DIDN'T ENJOY:
            \(lowRated.map { "- \($0.recipeName) (rated \($0.rating)/5)" }.joined(separator: "\n"))
            Avoid suggesting similar recipes.
            
            """
        }
        
        if !highRated.isEmpty {
            context += """
            
            RECIPES USER ENJOYED:
            \(highRated.map { "- \($0.recipeName) (rated \($0.rating)/5)" }.joined(separator: "\n"))
            Consider suggesting similar styles.
            
            """
        }
        
        // Add pantry staples (always available)
        let pantryItems = dataManager.pantryItems.map { $0.name }
        if !pantryItems.isEmpty {
            context += """
            
            PANTRY STAPLES (always available):
            \(pantryItems.map { "- \($0)" }.joined(separator: "\n"))
            
            """
        }
        
        // Add persisted fridge items (from previous scans)
        if dataManager.hasFridgeItems {
            let fridgeTimeAgo = dataManager.lastFridgeScanTimeAgo ?? "unknown"
            let fridgeItemsList = dataManager.fridgeItems.map { item -> String in
                if item.quantity.isEmpty {
                    return "- \(item.name)"
                } else {
                    return "- \(item.name) (\(item.quantity))"
                }
            }.joined(separator: "\n")
            
            context += """
            
            FRIDGE ITEMS (scanned \(fridgeTimeAgo)):
            \(fridgeItemsList)
            Note: These items may need freshness verification if scanned more than a few days ago.
            
            """
        }
        
        // Add detected ingredients from current session if available (overrides fridge items for current session)
        if !selectedIngredientNames.isEmpty {
            context += """
            
            CURRENTLY SELECTED INGREDIENTS (from active scan session):
            \(selectedIngredientNames.map { "- \($0)" }.joined(separator: "\n"))
            
            """
        } else if !detectedIngredients.isEmpty {
            context += """
            
            CURRENTLY DETECTED INGREDIENTS (from active scan session):
            \(detectedIngredients.map { "- \($0.name) (\($0.quantity))" }.joined(separator: "\n"))
            
            """
        }
        
        // Add generated recipes if available
        if !generatedRecipes.isEmpty {
            context += """
            
            RECIPES SUGGESTED TO USER:
            \(generatedRecipes.map { "- \($0.title): \($0.description)" }.joined(separator: "\n"))
            
            """
        }
        
        // Add current recipe context if user is discussing a specific recipe
        if let recipe = currentRecipeContext {
            context += """
            
            CURRENTLY DISCUSSING RECIPE: \(recipe.title)
            Description: \(recipe.description)
            Ingredients: \(recipe.ingredients.joined(separator: ", "))
            Steps: \(recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: " "))
            Prep Time: \(recipe.prepTime) min, Cook Time: \(recipe.cookTime) min
            Nutrition: \(recipe.macros.calories) cal, \(Int(recipe.macros.protein))g protein, \(Int(recipe.macros.carbs))g carbs, \(Int(recipe.macros.fats))g fat
            
            The user wants to modify or get help with this specific recipe.
            """
        }
        
        context += """
        
        INSTRUCTIONS:
        - Be helpful, friendly, and concise
        - Consider the user's dietary preferences and allergies in all suggestions
        - If asked about recipes, reference the ingredients they have available
        - Provide cooking tips and substitution ideas when relevant
        - Keep responses focused and practical
        """
        
        return context
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

