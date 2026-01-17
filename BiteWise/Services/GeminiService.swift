import Foundation
import UIKit

// MARK: - Gemini API Error Types

enum GeminiError: Error, LocalizedError {
    case invalidAPIKey
    case invalidImage
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError(Error)
    case demoMode
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key. Please add your Gemini API key in APIConfiguration.swift"
        case .invalidImage:
            return "Failed to process the image. Please try a different photo."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .demoMode:
            return "Running in demo mode - using sample data"
        }
    }
}

// MARK: - Gemini API Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiErrorResponse?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiErrorResponse: Codable {
    let message: String?
    let code: Int?
}

// MARK: - Gemini Service

class GeminiService {
    
    // MARK: - Singleton
    static let shared = GeminiService()
    
    // MARK: - Properties
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Image Analysis (Ingredient Detection)
    
    /// Analyze a fridge photo and detect ingredients
    /// - Parameter image: The UIImage of the fridge contents
    /// - Returns: Array of detected ingredients
    func analyzeImage(_ image: UIImage) async throws -> [DetectedIngredient] {
        // SAFETY CHECK: Demo mode bypass
        guard AppSettings.shared.shouldUseRealAPI else {
            print("📋 Demo Mode: Returning dummy ingredients (no API call)")
            // Simulate network delay for realistic UX
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return DetectedIngredient.dummyData
        }
        
        print("🌐 Live Mode: Calling Gemini Vision API...")
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        
        // Build the prompt for ingredient detection
        let prompt = """
        Analyze this image of food items/ingredients. List all visible food ingredients.
        
        Return ONLY a valid JSON object in this exact format, with no additional text:
        {
          "ingredients": [
            {"name": "ingredient name", "quantity": "estimated quantity", "category": "protein/vegetable/fruit/dairy/grain/condiment/other"}
          ]
        }
        
        Be specific with ingredient names. Estimate quantities when visible.
        Categories: protein, vegetable, fruit, dairy, grain, condiment, beverage, other
        """
        
        // Build request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]
        
        // Make API call
        let responseText = try await callGeminiAPI(requestBody: requestBody)
        
        // Parse JSON response
        return try parseIngredientsResponse(responseText)
    }
    
    // MARK: - Recipe Generation
    
    /// Generate recipes based on available ingredients and user preferences
    /// - Parameters:
    ///   - ingredients: List of fresh ingredient names (detected from fridge photo)
    ///   - pantryItems: List of pantry staples (from onboarding, always available)
    ///   - userProfile: User's profile with dietary preferences and allergies
    /// - Returns: Array of generated recipes
    func generateRecipes(ingredients: [String], pantryItems: [String], userProfile: UserProfile) async throws -> [Recipe] {
        // SAFETY CHECK: Demo mode bypass
        guard AppSettings.shared.shouldUseRealAPI else {
            print("📋 Demo Mode: Returning dummy recipes (no API call)")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return Array(Recipe.dummyData.prefix(5))
        }
        
        print("🌐 Live Mode: Calling Gemini API for recipe generation...")
        
        // Build the prompt with user context
        let allergiesText = userProfile.allergies.isEmpty ? "None" : userProfile.allergies.joined(separator: ", ")
        let preferencesText = userProfile.dietaryPreferences.isEmpty ? "None specified" : userProfile.dietaryPreferences.joined(separator: ", ")
        let pantryText = pantryItems.isEmpty ? "None specified" : pantryItems.joined(separator: ", ")
        
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
        
        // Add today's consumed macros if user has been tracking
        let dataManager = DataManager.shared
        let todayMacros = dataManager.dailyMacros
        let goals = dataManager.macroGoalsInGrams
        
        var consumptionText = ""
        if todayMacros.caloriesConsumed > 0 {
            let calRemaining = max(0, goals.calories - todayMacros.caloriesConsumed)
            let proteinRemaining = max(0, goals.protein - Int(todayMacros.proteinConsumed))
            consumptionText = """
            
            TODAY'S CONSUMPTION:
            - Already consumed: \(todayMacros.caloriesConsumed) cal, \(Int(todayMacros.proteinConsumed))g protein
            - Remaining budget: ~\(calRemaining) cal, ~\(proteinRemaining)g protein
            - Prioritize recipes that fit within remaining budget
            """
        }
        
        let prompt = """
        Generate 5 recipes using these available ingredients:
        
        FRESH INGREDIENTS (detected from fridge photo - primary focus): \(ingredients.joined(separator: ", "))
        
        PANTRY STAPLES (always available - can supplement recipes): \(pantryText)
        
        User dietary information:
        - Allergies (MUST AVOID): \(allergiesText)
        - Dietary Preferences: \(preferencesText)
        - Macros: \(macroText)\(consumptionText)
        
        Return ONLY a valid JSON object in this exact format, with no additional text:
        {
          "recipes": [
            {
              "title": "Recipe Name",
              "description": "Brief description (1-2 sentences)",
              "prepTime": 10,
              "cookTime": 20,
              "ingredients": ["ingredient 1 with quantity", "ingredient 2 with quantity"],
              "steps": ["Step 1 instruction", "Step 2 instruction"],
              "macros": {
                "calories": 350,
                "protein": 25,
                "carbs": 30,
                "fats": 12
              }
            }
          ]
        }
        
        Important:
        - Create recipes that primarily use the FRESH INGREDIENTS, supplemented by PANTRY STAPLES as needed
        - NEVER include ingredients the user is allergic to
        - Prioritize recipes that match their dietary preferences
        - Provide realistic macro estimates
        - Include prep and cook times in minutes
        - Make steps clear and actionable
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 4096
            ]
        ]
        
        let responseText = try await callGeminiAPI(requestBody: requestBody)
        return try parseRecipesResponse(responseText)
    }
    
    // MARK: - Chat
    
    /// Send a chat message with full session context
    /// - Parameters:
    ///   - message: The user's message
    ///   - context: Session context with ingredients and recipes
    ///   - userProfile: User's profile
    /// - Returns: AI response text
    func chat(message: String, context: SessionContext, userProfile: UserProfile) async throws -> String {
        // SAFETY CHECK: Demo mode bypass
        guard AppSettings.shared.shouldUseRealAPI else {
            print("📋 Demo Mode: Returning mock chat response (no API call)")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return generateMockChatResponse(for: message, context: context, userProfile: userProfile)
        }
        
        print("🌐 Live Mode: Calling Gemini API for chat...")
        
        // Build system context
        let systemContext = context.buildChatContext(userProfile: userProfile)
        
        // Build conversation history
        var conversationParts: [[String: Any]] = []
        
        // Add system context as first message
        conversationParts.append([
            "role": "user",
            "parts": [["text": "System Context:\n\(systemContext)"]]
        ])
        conversationParts.append([
            "role": "model",
            "parts": [["text": "I understand. I'm ready to help with cooking and recipe questions based on the available ingredients and user preferences."]]
        ])
        
        // Get the appropriate chat history based on current context
        let chatHistory: [ChatMessage]
        if let recipe = context.currentRecipeContext {
            chatHistory = context.getChatHistory(for: recipe.id)
        } else {
            chatHistory = context.generalChatHistory
        }
        
        // Add conversation history
        for chatMessage in chatHistory {
            let role = chatMessage.isUser ? "user" : "model"
            conversationParts.append([
                "role": role,
                "parts": [["text": chatMessage.text]]
            ])
        }
        
        // Add current message
        conversationParts.append([
            "role": "user",
            "parts": [["text": message]]
        ])
        
        let requestBody: [String: Any] = [
            "contents": conversationParts,
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        return try await callGeminiAPI(requestBody: requestBody)
    }
    
    // MARK: - Private Helper Methods
    
    /// Make the actual API call to Gemini
    private func callGeminiAPI(requestBody: [String: Any]) async throws -> String {
        guard APIConfiguration.hasValidAPIKey else {
            throw GeminiError.invalidAPIKey
        }
        
        let model = APIConfiguration.geminiModel
        let apiKey = APIConfiguration.geminiAPIKey
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        // Check for HTTP errors
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let errorMessage = errorResponse.error?.message {
                throw GeminiError.apiError(errorMessage)
            }
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        return text
    }
    
    /// Parse ingredients from Gemini response
    private func parseIngredientsResponse(_ text: String) throws -> [DetectedIngredient] {
        // Extract JSON from response (handle markdown code blocks if present)
        let jsonString = extractJSON(from: text)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        struct IngredientsResponse: Codable {
            let ingredients: [IngredientDTO]
            
            struct IngredientDTO: Codable {
                let name: String
                let quantity: String
                let category: String
            }
        }
        
        do {
            let response = try JSONDecoder().decode(IngredientsResponse.self, from: data)
            return response.ingredients.map { dto in
                DetectedIngredient(
                    name: dto.name,
                    quantity: dto.quantity,
                    category: dto.category
                )
            }
        } catch {
            throw GeminiError.decodingError(error)
        }
    }
    
    /// Parse recipes from Gemini response
    private func parseRecipesResponse(_ text: String) throws -> [Recipe] {
        let jsonString = extractJSON(from: text)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        struct RecipesResponse: Codable {
            let recipes: [RecipeDTO]
            
            struct RecipeDTO: Codable {
                let title: String
                let description: String
                let prepTime: Int
                let cookTime: Int
                let ingredients: [String]
                let steps: [String]
                let macros: MacrosDTO
                
                struct MacrosDTO: Codable {
                    let calories: Int
                    let protein: Double
                    let carbs: Double
                    let fats: Double
                }
            }
        }
        
        do {
            let response = try JSONDecoder().decode(RecipesResponse.self, from: data)
            return response.recipes.map { dto in
                Recipe(
                    title: dto.title,
                    description: dto.description,
                    imageNamePlaceholder: "generated_recipe",
                    ingredients: dto.ingredients,
                    steps: dto.steps,
                    prepTime: dto.prepTime,
                    cookTime: dto.cookTime,
                    macros: MacroNutrients(
                        protein: dto.macros.protein,
                        carbs: dto.macros.carbs,
                        fats: dto.macros.fats,
                        calories: dto.macros.calories
                    )
                )
            }
        } catch {
            throw GeminiError.decodingError(error)
        }
    }
    
    /// Extract JSON from text that might contain markdown code blocks
    private func extractJSON(from text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code block markers if present
        if result.hasPrefix("```json") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```") {
            result = String(result.dropFirst(3))
        }
        
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Generate mock chat responses for demo mode
    /// Now context-aware to demonstrate features even in demo mode
    private func generateMockChatResponse(for message: String, context: SessionContext, userProfile: UserProfile) -> String {
        let lowercased = message.lowercased()
        let dataManager = DataManager.shared
        
        // Build context-aware response elements
        var ingredientInfo = ""
        if !context.selectedIngredientNames.isEmpty {
            let ingredients = context.selectedIngredientNames.prefix(3).joined(separator: ", ")
            ingredientInfo = " I see you have \(ingredients) available."
        } else if dataManager.hasFridgeItems {
            let items = dataManager.fridgeItems.prefix(3).map { $0.name }.joined(separator: ", ")
            ingredientInfo = " Based on your fridge items (\(items)), "
        }
        
        var macroInfo = ""
        if dataManager.dailyMacros.caloriesConsumed > 0 {
            let goals = dataManager.macroGoalsInGrams
            let remaining = max(0, goals.calories - dataManager.dailyMacros.caloriesConsumed)
            macroInfo = " You have about \(remaining) calories remaining today."
        }
        
        var favoritesInfo = ""
        if dataManager.hasFavorites {
            let favName = dataManager.favoriteRecipes.first?.title ?? ""
            favoritesInfo = " Since you enjoyed \(favName), you might like something similar."
        }
        
        // Generate response based on message content
        if lowercased.contains("recipe") || lowercased.contains("cook") || lowercased.contains("make") {
            var response = "Based on your available ingredients, I'd suggest making a simple stir-fry or omelet."
            response += ingredientInfo
            response += macroInfo
            if !favoritesInfo.isEmpty {
                response += favoritesInfo
            }
            response += " Would you like detailed instructions?"
            return response
            
        } else if lowercased.contains("substitute") || lowercased.contains("replace") {
            return "Great question! Common substitutions include: Greek yogurt for sour cream, olive oil for butter, and cauliflower rice for regular rice. What specific ingredient are you looking to substitute?"
            
        } else if lowercased.contains("healthy") || lowercased.contains("protein") || lowercased.contains("calorie") || lowercased.contains("macro") {
            var response = "For a high-protein, lower-calorie meal, I'd recommend focusing on lean proteins like chicken breast or eggs with plenty of vegetables."
            response += macroInfo
            response += ingredientInfo.isEmpty ? "" : ingredientInfo
            return response
            
        } else if lowercased.contains("favorite") {
            if dataManager.hasFavorites {
                let favorites = dataManager.favoriteRecipes.prefix(3).map { $0.title }.joined(separator: ", ")
                return "Your favorite recipes include: \(favorites). Would you like me to suggest variations on any of these?"
            } else {
                return "You haven't saved any favorites yet. After trying some recipes, tap the heart icon to save them for easy access later!"
            }
            
        } else if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            var greeting = "Hello\(userProfile.name.isEmpty ? "" : " \(userProfile.name)")! I'm your BiteWise cooking assistant."
            greeting += ingredientInfo.isEmpty ? " I can help you with recipes, cooking tips, and ingredient substitutions." : ingredientInfo
            greeting += " What would you like help with?"
            return greeting
            
        } else {
            var response = "I can help you with recipes, cooking tips, ingredient substitutions, and nutritional advice."
            response += ingredientInfo
            response += macroInfo
            response += " What would you like to make today?"
            return response
        }
    }
}

