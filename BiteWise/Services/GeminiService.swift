import Foundation
import UIKit
import os.log

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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BiteWise", category: "GeminiService")
    
    private init() {}
    
    // MARK: - Image Analysis (Ingredient Detection)
    
    /// Analyze a fridge photo and detect ingredients
    /// - Parameter image: The UIImage of the fridge contents
    /// - Returns: Array of detected ingredients
    func analyzeImage(_ image: UIImage) async throws -> [DetectedIngredient] {
        // SAFETY CHECK: Demo mode bypass
        guard AppSettings.shared.shouldUseRealAPI else {
            logger.debug("Demo Mode: Returning dummy ingredients")
            // Simulate network delay for realistic UX
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return DetectedIngredient.dummyData
        }
        
        logger.info("Calling Gemini Vision API for ingredient detection")
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        List all food items in this image.
        
        Return ONLY valid JSON:
        {"ingredients":[{"name":"item name","quantity":"amount","category":"protein/vegetable/fruit/dairy/grain/condiment/beverage/other","isStaple":false}]}
        
        Be specific. Estimate quantities. Use exact category values.
        
        For each item, determine its isStaple status (boolean).
        Set to true ONLY for foundational ingredients that users rarely need to track exact quantities for (e.g., salt, black pepper, sugar, standard cooking oils, basic spices).
        Set to false for finite items that are used up in distinct quantities, even if they are stored in a pantry (e.g., a can of soup, a box of pasta, a bag of chips, snacks, perishables).
        When in doubt, default to false.
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
            logger.debug("Demo Mode: Returning dummy recipes")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return Array(Recipe.dummyData.prefix(5))
        }
        
        logger.info("Calling Gemini API for recipe generation")
        
        // Build compact user context
        let allergiesText = userProfile.allergies.isEmpty ? "None" : userProfile.allergies.joined(separator: ", ")
        let preferencesText = userProfile.dietaryPreferences.isEmpty ? "" : userProfile.dietaryPreferences.joined(separator: ", ")
        let pantryText = pantryItems.isEmpty ? "" : pantryItems.joined(separator: ", ")
        
        // Macro budget (compact)
        var budgetText = ""
        let (todayMacros, goals) = await MainActor.run {
            let dataManager = DataManager.shared
            return (dataManager.dailyMacros, dataManager.macroGoalsInGrams)
        }
        if todayMacros.caloriesConsumed > 0 && userProfile.hasMacroGoals {
            let calRemaining = max(0, goals.calories - todayMacros.caloriesConsumed)
            budgetText = "Remaining budget: ~\(calRemaining)cal"
        }
        
        let prompt = """
        Generate 5 recipes.
        
        INGREDIENTS: \(ingredients.joined(separator: ", "))
        \(pantryText.isEmpty ? "" : "PANTRY: \(pantryText)")
        ALLERGIES (NEVER use): \(allergiesText)
        \(preferencesText.isEmpty ? "" : "PREFERENCES: \(preferencesText)")
        \(budgetText)
        
        Return ONLY valid JSON:
        {"recipes":[{"title":"Name","description":"Brief desc","prepTime":10,"cookTime":20,"ingredients":["1 cup item"],"steps":["Step 1"],"macros":{"calories":350,"protein":25,"carbs":30,"fats":12},"cookingSteps":[{"title":"Short step name","instruction":"Detailed step instruction","durationMinutes":5,"ingredients":["items used in this step"],"chefTip":"Practical tip specific to this step"}]}]}
        
        Rules: Use available ingredients. Never use allergens. Realistic macros. Clear steps.
        Each recipe MUST include cookingSteps with a title, detailed instruction, realistic durationMinutes, the specific ingredients used in that step, and a practical chef's tip relevant to that step. Every ingredient must appear in at least one cookingStep. The sum of all durationMinutes should roughly equal prepTime + cookTime.
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
                "maxOutputTokens": 8192
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
            logger.debug("Demo Mode: Returning mock chat response")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return await generateMockChatResponse(for: message, context: context, userProfile: userProfile)
        }
        
        logger.info("Calling Gemini API for chat")
        
        // Build system context (from main actor)
        let (systemContext, chatHistory) = await MainActor.run {
            let systemContext = context.buildChatContext(userProfile: userProfile)
            let chatHistory: [ChatMessage]
            if let recipe = context.currentRecipeContext {
                chatHistory = context.getChatHistory(for: recipe.id)
            } else {
                chatHistory = context.generalChatHistory
            }
            return (systemContext, chatHistory)
        }
        
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
    
    // MARK: - Chat Recipe Generation
    
    /// Generate a single recipe based on chat conversation context
    /// Used when the AI determines a recipe should be shown to the user
    /// - Parameters:
    ///   - description: Description of what recipe to generate (from AI's GENERATE_RECIPE marker)
    ///   - context: Session context with ingredients and conversation history
    ///   - userProfile: User's profile with dietary preferences and allergies
    ///   - baseRecipe: Optional base recipe if modifying an existing recipe
    /// - Returns: A single generated Recipe
    func generateRecipeFromChat(
        description: String,
        context: SessionContext,
        userProfile: UserProfile,
        baseRecipe: Recipe? = nil
    ) async throws -> Recipe {
        let (selectedIngredientNames, detectedIngredients, currentRecipeContext, hasFridgeItems, fridgeItems, pantryItems) = await MainActor.run {
            let dataManager = DataManager.shared
            return (
                context.selectedIngredientNames,
                context.detectedIngredients,
                context.currentRecipeContext,
                dataManager.hasFridgeItems,
                dataManager.fridgeItems,
                dataManager.pantryItems
            )
        }

        // SAFETY CHECK: Demo mode bypass
        guard AppSettings.shared.shouldUseRealAPI else {
            logger.debug("Demo Mode: Returning generated demo recipe")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return generateMockRecipeFromChat(description: description, currentRecipeContext: currentRecipeContext, baseRecipe: baseRecipe)
        }
        
        logger.info("Calling Gemini API for chat recipe generation")
        
        // Build compact user context
        let allergiesText = userProfile.allergies.isEmpty ? "None" : userProfile.allergies.joined(separator: ", ")
        let preferencesText = userProfile.dietaryPreferences.isEmpty ? "" : userProfile.dietaryPreferences.joined(separator: ", ")
        
        // Available ingredients (prioritized)
        var ingredientsText = ""
        if !selectedIngredientNames.isEmpty {
            ingredientsText = selectedIngredientNames.joined(separator: ", ")
        } else if !detectedIngredients.isEmpty {
            ingredientsText = detectedIngredients.map { $0.name }.joined(separator: ", ")
        } else if hasFridgeItems {
            ingredientsText = fridgeItems.prefix(15).map { $0.name }.joined(separator: ", ")
        }
        
        // Pantry (compact)
        let pantryText = pantryItems.isEmpty ? "" : pantryItems.prefix(10).map { $0.name }.joined(separator: ", ")
        
        // Base recipe context if modifying (compact)
        var baseRecipeText = ""
        if let base = baseRecipe ?? currentRecipeContext {
            baseRecipeText = """
            
            MODIFY: \(base.title)
            Current ingredients: \(base.ingredients.joined(separator: ", "))
            \(base.macros.calories)cal | \(Int(base.macros.protein))gP | \(base.prepTime + base.cookTime)min
            """
        }
        
        let prompt = """
        Generate ONE recipe: \(description)
        
        ALLERGIES (NEVER use): \(allergiesText)
        \(preferencesText.isEmpty ? "" : "PREFERENCES: \(preferencesText)")
        \(ingredientsText.isEmpty ? "" : "INGREDIENTS: \(ingredientsText)")
        \(pantryText.isEmpty ? "" : "PANTRY: \(pantryText)")\(baseRecipeText)
        
        Return ONLY valid JSON:
        {"title":"Name","description":"Brief desc","prepTime":10,"cookTime":20,"ingredients":["1 cup item"],"steps":["Step 1"],"macros":{"calories":350,"protein":25,"carbs":30,"fats":12},"cookingSteps":[{"title":"Short step name","instruction":"Detailed step instruction","durationMinutes":5,"ingredients":["items used in this step"],"chefTip":"Practical tip specific to this step"}]}
        
        Rules: Never use allergens. Use available ingredients. Realistic macros. Clear steps.
        MUST include cookingSteps with a title, detailed instruction, realistic durationMinutes, the specific ingredients used in that step, and a practical chef's tip relevant to that step. Every ingredient must appear in at least one cookingStep. The sum of all durationMinutes should roughly equal prepTime + cookTime.
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
        return try parseSingleRecipeResponse(responseText)
    }
    
    // MARK: - Recipe Marker Detection
    
    /// Check if a chat response contains a recipe generation marker
    /// - Parameter response: The AI's response text
    /// - Returns: True if the response contains [GENERATE_RECIPE: ...]
    func containsRecipeMarker(_ response: String) -> Bool {
        return response.contains("[GENERATE_RECIPE:")
    }
    
    /// Extract the recipe description from a response with a recipe marker
    /// - Parameter response: The AI's response text
    /// - Returns: The recipe description, or nil if no marker found
    func extractRecipeDescription(from response: String) -> String? {
        guard let startRange = response.range(of: "[GENERATE_RECIPE:") else {
            return nil
        }
        
        let afterMarker = response[startRange.upperBound...]
        guard let endRange = afterMarker.range(of: "]") else {
            return nil
        }
        
        let description = String(afterMarker[..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return description.isEmpty ? nil : description
    }
    
    /// Remove the recipe marker from a response, leaving clean text for display
    /// - Parameter response: The AI's response text
    /// - Returns: The response with the marker removed
    func cleanRecipeMarker(from response: String) -> String {
        guard let startRange = response.range(of: "[GENERATE_RECIPE:") else {
            return response
        }
        
        let afterMarker = response[startRange.upperBound...]
        guard let endRange = afterMarker.range(of: "]") else {
            return response
        }
        
        // Calculate the full range including the closing bracket
        let fullEndIndex = afterMarker.index(endRange.lowerBound, offsetBy: 1)
        let markerRange = startRange.lowerBound..<fullEndIndex
        
        var cleaned = response
        cleaned.removeSubrange(markerRange)
        
        // Clean up any double spaces or leading/trailing whitespace
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
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
                let isStaple: Bool?
            }
        }
        
        do {
            let response = try JSONDecoder().decode(IngredientsResponse.self, from: data)
            return response.ingredients.map { dto in
                DetectedIngredient(
                    name: dto.name,
                    quantity: dto.quantity,
                    category: dto.category,
                    isStaple: dto.isStaple ?? false
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
                let cookingSteps: [CookingStepDTO]?
                
                struct MacrosDTO: Codable {
                    let calories: Int
                    let protein: Double
                    let carbs: Double
                    let fats: Double
                }
                
                struct CookingStepDTO: Codable {
                    let title: String
                    let instruction: String
                    let durationMinutes: Int
                    let ingredients: [String]
                    let chefTip: String
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
                    ),
                    cookingSteps: dto.cookingSteps?.map { step in
                        CookingStep(
                            title: step.title,
                            instruction: step.instruction,
                            durationMinutes: step.durationMinutes,
                            ingredients: step.ingredients,
                            chefTip: step.chefTip
                        )
                    }
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
    
    /// Parse a single recipe from Gemini response (for chat-generated recipes)
    private func parseSingleRecipeResponse(_ text: String) throws -> Recipe {
        let jsonString = extractJSON(from: text)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        struct SingleRecipeDTO: Codable {
            let title: String
            let description: String
            let prepTime: Int
            let cookTime: Int
            let ingredients: [String]
            let steps: [String]
            let macros: MacrosDTO
            let cookingSteps: [CookingStepDTO]?
            
            struct MacrosDTO: Codable {
                let calories: Int
                let protein: Double
                let carbs: Double
                let fats: Double
            }
            
            struct CookingStepDTO: Codable {
                let title: String
                let instruction: String
                let durationMinutes: Int
                let ingredients: [String]
                let chefTip: String
            }
        }
        
        do {
            let dto = try JSONDecoder().decode(SingleRecipeDTO.self, from: data)
            return Recipe(
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
                ),
                cookingSteps: dto.cookingSteps?.map { step in
                    CookingStep(
                        title: step.title,
                        instruction: step.instruction,
                        durationMinutes: step.durationMinutes,
                        ingredients: step.ingredients,
                        chefTip: step.chefTip
                    )
                }
            )
        } catch {
            throw GeminiError.decodingError(error)
        }
    }
    
    /// Generate a mock recipe for demo mode based on chat context
    private func generateMockRecipeFromChat(
        description: String,
        currentRecipeContext: Recipe?,
        baseRecipe: Recipe?
    ) -> Recipe {
        let lowercased = description.lowercased()
        
        // If modifying an existing recipe, create a variation
        if let base = baseRecipe ?? currentRecipeContext {
            return createModifiedRecipe(base: base, description: description)
        }
        
        // Generate based on keywords in description
        if lowercased.contains("high protein") || lowercased.contains("protein") {
            return Recipe(
                title: "High-Protein Power Bowl",
                description: "A protein-packed bowl with grilled chicken, quinoa, and fresh vegetables.",
                imageNamePlaceholder: "generated_recipe",
                ingredients: [
                    "8 oz chicken breast",
                    "1 cup cooked quinoa",
                    "1 cup mixed greens",
                    "1/2 cup cherry tomatoes",
                    "1/4 avocado",
                    "2 tbsp olive oil",
                    "Lemon juice to taste"
                ],
                steps: [
                    "Season chicken breast with salt, pepper, and herbs",
                    "Grill chicken for 6-7 minutes per side until cooked through",
                    "Let chicken rest for 5 minutes, then slice",
                    "Arrange quinoa as base in a bowl",
                    "Top with mixed greens, tomatoes, and sliced chicken",
                    "Add avocado slices and drizzle with olive oil and lemon"
                ],
                prepTime: 10,
                cookTime: 15,
                macros: MacroNutrients(protein: 42, carbs: 35, fats: 18, calories: 480),
                cookingSteps: [
                    CookingStep(title: "Season the chicken", instruction: "Season chicken breast with salt, pepper, and your favorite herbs on both sides.", durationMinutes: 2, ingredients: ["8 oz chicken breast"], chefTip: "Let the seasoned chicken sit for a few minutes so the salt draws out moisture for a better sear."),
                    CookingStep(title: "Grill the chicken", instruction: "Grill chicken for 6-7 minutes per side until the internal temperature reaches 165°F.", durationMinutes: 14, ingredients: ["8 oz chicken breast"], chefTip: "Only flip the chicken once -- resist the urge to move it around for the best grill marks."),
                    CookingStep(title: "Rest and slice", instruction: "Let the chicken rest for 5 minutes on a cutting board, then slice against the grain.", durationMinutes: 6, ingredients: ["8 oz chicken breast"], chefTip: "Resting lets the juices redistribute -- cutting too early means dry chicken."),
                    CookingStep(title: "Build the bowl", instruction: "Arrange quinoa as a base in a bowl. Top with mixed greens, halved cherry tomatoes, and sliced chicken.", durationMinutes: 2, ingredients: ["1 cup cooked quinoa", "1 cup mixed greens", "1/2 cup cherry tomatoes"], chefTip: "Warm the quinoa slightly before assembling for a more satisfying bowl."),
                    CookingStep(title: "Finish and serve", instruction: "Add avocado slices and drizzle with olive oil and fresh lemon juice.", durationMinutes: 1, ingredients: ["1/4 avocado", "2 tbsp olive oil", "Lemon juice to taste"], chefTip: "Cut the avocado right before serving to prevent browning.")
                ]
            )
        } else if lowercased.contains("low carb") || lowercased.contains("keto") {
            return Recipe(
                title: "Keto Cauliflower Stir-Fry",
                description: "A low-carb stir-fry using cauliflower rice with vegetables and your choice of protein.",
                imageNamePlaceholder: "generated_recipe",
                ingredients: [
                    "2 cups cauliflower rice",
                    "6 oz protein of choice",
                    "1 cup mixed bell peppers",
                    "2 tbsp coconut aminos",
                    "1 tbsp sesame oil",
                    "2 cloves garlic, minced",
                    "Green onions for garnish"
                ],
                steps: [
                    "Heat sesame oil in a large pan over high heat",
                    "Cook protein until done, set aside",
                    "Sauté garlic and peppers for 2-3 minutes",
                    "Add cauliflower rice and cook for 4-5 minutes",
                    "Return protein to pan, add coconut aminos",
                    "Toss everything together and garnish with green onions"
                ],
                prepTime: 10,
                cookTime: 12,
                macros: MacroNutrients(protein: 28, carbs: 12, fats: 16, calories: 310)
            )
        } else if lowercased.contains("quick") || lowercased.contains("fast") || lowercased.contains("easy") {
            return Recipe(
                title: "15-Minute Veggie Scramble",
                description: "A quick and nutritious egg scramble loaded with fresh vegetables.",
                imageNamePlaceholder: "generated_recipe",
                ingredients: [
                    "3 large eggs",
                    "1/4 cup diced bell pepper",
                    "1/4 cup spinach",
                    "2 tbsp cheese",
                    "1 tbsp butter",
                    "Salt and pepper to taste"
                ],
                steps: [
                    "Whisk eggs with salt and pepper",
                    "Melt butter in a non-stick pan over medium heat",
                    "Sauté bell pepper for 2 minutes",
                    "Add spinach and cook until wilted",
                    "Pour in eggs and gently scramble",
                    "Top with cheese and serve immediately"
                ],
                prepTime: 5,
                cookTime: 8,
                macros: MacroNutrients(protein: 21, carbs: 4, fats: 22, calories: 295),
                cookingSteps: [
                    CookingStep(title: "Prep the eggs", instruction: "Whisk eggs with a pinch of salt and pepper until well combined.", durationMinutes: 1, ingredients: ["3 large eggs", "Salt and pepper to taste"], chefTip: "Add a tiny splash of water to the eggs for a fluffier scramble."),
                    CookingStep(title: "Heat the pan", instruction: "Melt butter in a non-stick pan over medium heat until it starts to foam.", durationMinutes: 1, ingredients: ["1 tbsp butter"], chefTip: "Medium heat is key -- too hot and you'll get rubbery eggs."),
                    CookingStep(title: "Sauté the peppers", instruction: "Add diced bell pepper and sauté for 2 minutes until slightly softened.", durationMinutes: 2, ingredients: ["1/4 cup diced bell pepper"], chefTip: "Keep the peppers slightly crisp for a nice textural contrast."),
                    CookingStep(title: "Wilt the spinach", instruction: "Add spinach to the pan and cook for about 30 seconds until just wilted.", durationMinutes: 1, ingredients: ["1/4 cup spinach"], chefTip: "Spinach reduces dramatically in volume -- don't worry if it looks like a lot."),
                    CookingStep(title: "Scramble the eggs", instruction: "Pour in the whisked eggs and gently push them from the edges toward the center, forming soft curds.", durationMinutes: 3, ingredients: ["3 large eggs"], chefTip: "Pull the pan off heat while eggs are still slightly wet -- they'll finish cooking from residual heat."),
                    CookingStep(title: "Top and serve", instruction: "Sprinkle cheese on top and serve immediately while hot.", durationMinutes: 1, ingredients: ["2 tbsp cheese"], chefTip: "Let the cheese melt on the hot eggs for 30 seconds before plating.")
                ]
            )
        } else if lowercased.contains("vegetarian") || lowercased.contains("veggie") {
            return Recipe(
                title: "Mediterranean Chickpea Bowl",
                description: "A hearty vegetarian bowl with chickpeas, fresh vegetables, and tahini dressing.",
                imageNamePlaceholder: "generated_recipe",
                ingredients: [
                    "1 can chickpeas, drained",
                    "1 cucumber, diced",
                    "1 cup cherry tomatoes",
                    "1/4 red onion, sliced",
                    "2 tbsp tahini",
                    "Juice of 1 lemon",
                    "Fresh parsley"
                ],
                steps: [
                    "Rinse and drain chickpeas",
                    "Chop all vegetables",
                    "Combine chickpeas and vegetables in a bowl",
                    "Whisk tahini with lemon juice and water to thin",
                    "Drizzle dressing over bowl",
                    "Garnish with fresh parsley"
                ],
                prepTime: 10,
                cookTime: 0,
                macros: MacroNutrients(protein: 15, carbs: 45, fats: 12, calories: 340)
            )
        } else {
            // Default recipe
            return Recipe(
                title: "Simple Chicken & Vegetables",
                description: "A balanced meal with seasoned chicken and roasted vegetables.",
                imageNamePlaceholder: "generated_recipe",
                ingredients: [
                    "6 oz chicken breast",
                    "1 cup broccoli florets",
                    "1 cup diced sweet potato",
                    "2 tbsp olive oil",
                    "Italian seasoning",
                    "Salt and pepper"
                ],
                steps: [
                    "Preheat oven to 400°F (200°C)",
                    "Cut chicken and vegetables into even pieces",
                    "Toss everything with olive oil and seasonings",
                    "Spread on a baking sheet in a single layer",
                    "Roast for 25-30 minutes until chicken is cooked through",
                    "Let rest for 5 minutes before serving"
                ],
                prepTime: 10,
                cookTime: 30,
                macros: MacroNutrients(protein: 35, carbs: 28, fats: 14, calories: 385),
                cookingSteps: [
                    CookingStep(title: "Preheat the oven", instruction: "Preheat your oven to 400°F (200°C). Position the rack in the center.", durationMinutes: 1, ingredients: [], chefTip: "A fully preheated oven is essential for even roasting and crispy edges."),
                    CookingStep(title: "Prep the ingredients", instruction: "Cut chicken breast and sweet potato into even 1-inch pieces. Break broccoli into bite-sized florets.", durationMinutes: 7, ingredients: ["6 oz chicken breast", "1 cup broccoli florets", "1 cup diced sweet potato"], chefTip: "Even-sized pieces cook at the same rate -- this is the secret to perfectly roasted sheet pan meals."),
                    CookingStep(title: "Season everything", instruction: "Toss all pieces with olive oil, Italian seasoning, salt, and pepper in a large bowl until well coated.", durationMinutes: 2, ingredients: ["2 tbsp olive oil", "Italian seasoning", "Salt and pepper"], chefTip: "Use your hands to toss -- it gives the most even coating compared to a spoon."),
                    CookingStep(title: "Arrange and roast", instruction: "Spread everything on a baking sheet in a single layer without crowding. Roast for 25-30 minutes.", durationMinutes: 28, ingredients: ["6 oz chicken breast", "1 cup broccoli florets", "1 cup diced sweet potato"], chefTip: "Don't crowd the pan -- if pieces touch, they steam instead of roast. Use two sheets if needed."),
                    CookingStep(title: "Rest and serve", instruction: "Remove from oven and let rest for 5 minutes before plating. The chicken continues to cook slightly while resting.", durationMinutes: 5, ingredients: [], chefTip: "Check the chicken with a thermometer -- 165°F internal means it's perfectly done.")
                ]
            )
        }
    }
    
    /// Create a modified version of an existing recipe based on user request
    private func createModifiedRecipe(base: Recipe, description: String) -> Recipe {
        let lowercased = description.lowercased()
        var modified = base
        modified.id = UUID()
        
        let substituteIngredient: (String) -> String = { ingredient in
            let lower = ingredient.lowercased()
            if lowercased.contains("dairy-free") || lowercased.contains("dairy free") {
                if lower.contains("cheese") { return ingredient.replacingOccurrences(of: "cheese", with: "nutritional yeast", options: .caseInsensitive) }
                if lower.contains("butter") { return ingredient.replacingOccurrences(of: "butter", with: "olive oil", options: .caseInsensitive) }
                if lower.contains("milk") { return ingredient.replacingOccurrences(of: "milk", with: "almond milk", options: .caseInsensitive) }
                if lower.contains("cream") { return ingredient.replacingOccurrences(of: "cream", with: "coconut cream", options: .caseInsensitive) }
            } else if lowercased.contains("low carb") || lowercased.contains("fewer carbs") || lowercased.contains("reduce carbs") {
                if lower.contains("pasta") || lower.contains("spaghetti") {
                    return ingredient.replacingOccurrences(of: "pasta", with: "zucchini noodles", options: .caseInsensitive)
                        .replacingOccurrences(of: "spaghetti", with: "zucchini noodles", options: .caseInsensitive)
                }
                if lower.contains("rice") && !lower.contains("cauliflower") { return ingredient.replacingOccurrences(of: "rice", with: "cauliflower rice", options: .caseInsensitive) }
                if lower.contains("potato") { return ingredient.replacingOccurrences(of: "potato", with: "cauliflower", options: .caseInsensitive) }
            } else if lowercased.contains("vegetarian") {
                if lower.contains("chicken") || lower.contains("beef") || lower.contains("pork") { return "1 block firm tofu, cubed" }
                if lower.contains("bacon") || lower.contains("pancetta") { return "4 oz smoked tempeh" }
            }
            return ingredient
        }
        
        if lowercased.contains("dairy-free") || lowercased.contains("dairy free") {
            modified.title = "Dairy-Free \(base.title)"
            modified.description = "A dairy-free version of \(base.title). \(base.description)"
            modified.ingredients = base.ingredients.map(substituteIngredient)
        } else if lowercased.contains("spicy") || lowercased.contains("spicier") {
            modified.title = "Spicy \(base.title)"
            modified.description = "A spicier version with added heat. \(base.description)"
            modified.ingredients.append("1 tsp red pepper flakes")
            modified.ingredients.append("1 jalapeño, sliced (optional)")
        } else if lowercased.contains("low carb") || lowercased.contains("fewer carbs") || lowercased.contains("reduce carbs") {
            modified.title = "Low-Carb \(base.title)"
            modified.description = "A lower-carb adaptation. \(base.description)"
            modified.ingredients = base.ingredients.map(substituteIngredient)
            modified.macros.carbs = max(5, base.macros.carbs * 0.4)
            modified.macros.calories = max(200, base.macros.calories - 100)
        } else if lowercased.contains("more protein") || lowercased.contains("high protein") {
            modified.title = "High-Protein \(base.title)"
            modified.description = "Boosted with extra protein. \(base.description)"
            modified.ingredients.append("4 oz extra lean protein")
            modified.macros.protein = base.macros.protein + 25
            modified.macros.calories = base.macros.calories + 120
        } else if lowercased.contains("vegetarian") {
            modified.title = "Vegetarian \(base.title)"
            modified.description = "A meat-free version. \(base.description)"
            modified.ingredients = base.ingredients.map(substituteIngredient)
        } else {
            modified.title = "Modified \(base.title)"
            modified.description = "Customized based on your preferences. \(base.description)"
        }
        
        modified.cookingSteps = base.cookingSteps?.map { step in
            var modifiedStep = step
            modifiedStep.ingredients = step.ingredients.map(substituteIngredient)
            return modifiedStep
        }
        
        return modified
    }
    
    /// Generate mock chat responses for demo mode
    /// Now context-aware to demonstrate features even in demo mode
    /// Includes [GENERATE_RECIPE: ...] markers when appropriate to trigger recipe card generation
    private func generateMockChatResponse(for message: String, context: SessionContext, userProfile: UserProfile) async -> String {
        let lowercased = message.lowercased()
        let (selectedIngredientNames, currentRecipeContext, hasFridgeItems, fridgeItems, dailyMacros, goals, hasFavorites, favoriteRecipes) = await MainActor.run {
            let dataManager = DataManager.shared
            return (
                context.selectedIngredientNames,
                context.currentRecipeContext,
                dataManager.hasFridgeItems,
                dataManager.fridgeItems,
                dataManager.dailyMacros,
                dataManager.macroGoalsInGrams,
                dataManager.hasFavorites,
                dataManager.favoriteRecipes
            )
        }
        
        // Build context-aware response elements
        var ingredientInfo = ""
        if !selectedIngredientNames.isEmpty {
            let ingredients = selectedIngredientNames.prefix(3).joined(separator: ", ")
            ingredientInfo = " I see you have \(ingredients) available."
        } else if hasFridgeItems {
            let items = fridgeItems.prefix(3).map { $0.name }.joined(separator: ", ")
            ingredientInfo = " Based on your fridge items (\(items)), "
        }
        
        var macroInfo = ""
        if dailyMacros.caloriesConsumed > 0 {
            let remaining = max(0, goals.calories - dailyMacros.caloriesConsumed)
            macroInfo = " You have about \(remaining) calories remaining today."
        }
        
        // Check if user is asking for a recipe or modifications - these should generate recipe cards
        let wantsRecipe = lowercased.contains("show") || lowercased.contains("suggest") || 
                          lowercased.contains("give me") || lowercased.contains("what can i") ||
                          lowercased.contains("recommend") || lowercased.contains("yes") ||
                          lowercased.contains("sure") || lowercased.contains("please")
        
        let wantsModification = lowercased.contains("make it") || lowercased.contains("change") ||
                               lowercased.contains("modify") || lowercased.contains("adjust") ||
                               lowercased.contains("without") || lowercased.contains("less") ||
                               lowercased.contains("more") || lowercased.contains("dairy-free") ||
                               lowercased.contains("dairy free") || lowercased.contains("spicy") ||
                               lowercased.contains("spicier") || lowercased.contains("vegetarian") ||
                               lowercased.contains("vegan") || lowercased.contains("low carb") ||
                               lowercased.contains("low-carb") || lowercased.contains("keto")
        
        // If modifying an existing recipe
        if wantsModification && currentRecipeContext != nil {
            let modification = extractModificationType(from: lowercased)
            return "Here's an updated version with your changes: [GENERATE_RECIPE: \(modification) version of the current recipe]"
        }
        
        // Generate response based on message content
        if lowercased.contains("recipe") || lowercased.contains("cook") || lowercased.contains("make") {
            // If they're asking for a specific type of recipe, generate it
            if wantsRecipe || lowercased.contains("dinner") || lowercased.contains("lunch") || 
               lowercased.contains("breakfast") || lowercased.contains("snack") {
                let mealType = extractMealType(from: lowercased)
                var response = "Here's a great \(mealType) option for you:"
                response += ingredientInfo
                response += " [GENERATE_RECIPE: \(mealType) using available ingredients]"
                return response
            }
            
            // Otherwise ask what they'd like
            var response = "I'd be happy to help you cook something!"
            response += ingredientInfo
            response += macroInfo
            response += " What type of meal are you in the mood for?"
            return response
            
        } else if lowercased.contains("high protein") || lowercased.contains("high-protein") || lowercased.contains("protein") {
            if wantsRecipe {
                return "Here's a protein-packed recipe for you:\(macroInfo) [GENERATE_RECIPE: high-protein meal using available ingredients]"
            }
            var response = "For a high-protein meal, I'd recommend focusing on lean proteins like chicken breast or eggs with plenty of vegetables."
            response += macroInfo
            response += ingredientInfo.isEmpty ? "" : ingredientInfo
            response += " Would you like me to suggest a specific recipe?"
            return response
            
        } else if lowercased.contains("quick") || lowercased.contains("fast") || lowercased.contains("easy") || lowercased.contains("simple") {
            if wantsRecipe {
                return "Here's a quick and easy recipe you can make in no time: [GENERATE_RECIPE: quick easy meal under 20 minutes]"
            }
            return "I can suggest some quick recipes that take under 20 minutes. Would you like me to show you one?"
            
        } else if lowercased.contains("healthy") || lowercased.contains("light") {
            if wantsRecipe {
                return "Here's a healthy option for you:\(macroInfo) [GENERATE_RECIPE: healthy balanced meal]"
            }
            var response = "For a healthy, balanced meal, I'd recommend something with lean protein and lots of vegetables."
            response += macroInfo
            return response + " Want me to suggest a specific recipe?"
            
        } else if lowercased.contains("low carb") || lowercased.contains("low-carb") || lowercased.contains("keto") {
            if wantsRecipe {
                return "Here's a low-carb option that fits your goals: [GENERATE_RECIPE: low-carb keto-friendly meal]"
            }
            return "I can help with low-carb recipes! Would you like me to suggest one?"
            
        } else if lowercased.contains("vegetarian") || lowercased.contains("veggie") || lowercased.contains("meatless") {
            if wantsRecipe {
                return "Here's a delicious vegetarian recipe: [GENERATE_RECIPE: vegetarian meal with plant-based protein]"
            }
            return "I have some great vegetarian options! Would you like me to show you one?"
            
        } else if lowercased.contains("substitute") || lowercased.contains("replace") {
            return "Great question! Common substitutions include: Greek yogurt for sour cream, olive oil for butter, and cauliflower rice for regular rice. What specific ingredient are you looking to substitute?"
            
        } else if lowercased.contains("favorite") {
            if hasFavorites {
                let favorites = favoriteRecipes.prefix(3).map { $0.title }.joined(separator: ", ")
                return "Your favorite recipes include: \(favorites). Would you like me to suggest variations on any of these?"
            } else {
                return "You haven't saved any favorites yet. After trying some recipes, tap the heart icon to save them for easy access later!"
            }
            
        } else if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            var greeting = "Hello\(userProfile.name.isEmpty ? "" : " \(userProfile.name)")! I'm your BiteWise cooking assistant."
            greeting += ingredientInfo.isEmpty ? " I can help you with recipes, cooking tips, and ingredient substitutions." : ingredientInfo
            greeting += " What would you like help with?"
            return greeting
            
        } else if wantsRecipe {
            // Generic "yes" or "please" response - suggest a recipe
            return "Here's a recipe I think you'll enjoy:\(ingredientInfo) [GENERATE_RECIPE: balanced meal using available ingredients]"
            
        } else {
            var response = "I can help you with recipes, cooking tips, ingredient substitutions, and nutritional advice."
            response += ingredientInfo
            response += macroInfo
            response += " What would you like to make today?"
            return response
        }
    }
    
    /// Extract the type of modification requested from user message
    private func extractModificationType(from message: String) -> String {
        if message.contains("dairy-free") || message.contains("dairy free") || message.contains("no dairy") {
            return "dairy-free"
        } else if message.contains("spicy") || message.contains("spicier") {
            return "spicier"
        } else if message.contains("vegetarian") || message.contains("no meat") || message.contains("meatless") {
            return "vegetarian"
        } else if message.contains("vegan") {
            return "vegan"
        } else if message.contains("low carb") || message.contains("low-carb") || message.contains("fewer carbs") || message.contains("less carbs") {
            return "low-carb"
        } else if message.contains("more protein") || message.contains("high protein") || message.contains("high-protein") {
            return "high-protein"
        } else if message.contains("gluten-free") || message.contains("gluten free") || message.contains("no gluten") {
            return "gluten-free"
        } else if message.contains("less") {
            return "lighter"
        } else if message.contains("more") {
            return "heartier"
        }
        return "modified"
    }
    
    /// Extract the meal type from user message
    private func extractMealType(from message: String) -> String {
        if message.contains("breakfast") {
            return "breakfast"
        } else if message.contains("lunch") {
            return "lunch"
        } else if message.contains("dinner") {
            return "dinner"
        } else if message.contains("snack") {
            return "snack"
        } else if message.contains("dessert") {
            return "healthy dessert"
        }
        return "meal"
    }
}
