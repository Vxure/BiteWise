//
//  AuthDataSyncIntegrationTests.swift
//  BiteWiseTests
//
//  Integration tests for authentication and data sync flow.
//  Tests the complete flow: signup -> onboarding -> data persists -> logout -> login -> data loads
//

import Testing
import Foundation
@testable import BiteWise

// MARK: - Test Fixtures

/// Test data fixtures for consistent testing
struct TestFixtures {
    
    static let testUserProfile = UserProfile(
        name: "Test User",
        email: "test@example.com",
        dietaryPreferences: ["Vegetarian"],
        allergies: ["Gluten"],
        macroGoals: UserProfile.MacroGoals(
            dailyCalories: 1800,
            proteinPercentage: 25,
            carbsPercentage: 50,
            fatsPercentage: 25
        ),
        hasMacroGoals: true
    )
    
    static let testFridgeItems: [FridgeItem] = [
        FridgeItem(name: "Chicken Breast", quantity: "2 lbs", category: "protein"),
        FridgeItem(name: "Milk", quantity: "1 gallon", category: "dairy"),
        FridgeItem(name: "Spinach", quantity: "1 bag", category: "vegetable")
    ]
    
    static let testPantryItems: [Ingredient] = [
        Ingredient(name: "Rice", quantity: "2", unit: "cups", isStaple: true),
        Ingredient(name: "Olive Oil", quantity: "500", unit: "ml", isStaple: true),
        Ingredient(name: "Salt", quantity: "1", unit: "box", isStaple: true)
    ]
    
    static let testRecipe = Recipe(
        title: "Test Recipe",
        description: "A test recipe for integration testing",
        imageNamePlaceholder: "",
        ingredients: ["2 chicken breasts", "1 cup rice", "1 tbsp olive oil"],
        steps: ["Cook rice", "Grill chicken", "Serve together"],
        prepTime: 10,
        cookTime: 30,
        macros: MacroNutrients(protein: 45, carbs: 55, fats: 12, calories: 500)
    )
    
    static let testDailyMacroLog: DailyMacroLog = {
        var log = DailyMacroLog()
        log.caloriesConsumed = 1200
        log.proteinConsumed = 80
        log.carbsConsumed = 120
        log.fatsConsumed = 45
        return log
    }()
}

// MARK: - AuthService Unit Tests

@Suite("AuthService Tests")
struct AuthServiceTests {
    
    @Test("AuthError provides correct error descriptions")
    func authErrorDescriptions() {
        let errors: [AuthError] = [
            .invalidCredentials,
            .emailNotConfirmed,
            .userAlreadyExists,
            .weakPassword,
            .invalidEmail,
            .networkError,
            .sessionExpired,
            .rateLimited(retryAfter: 60),
            .verificationLinkExpired,
            .unknown("Custom error")
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have a description")
            #expect(!error.errorDescription!.isEmpty, "Error description should not be empty")
        }
    }
    
    @Test("AuthError isRetryable returns correct value")
    func authErrorIsRetryable() {
        // Network errors should be retryable
        #expect(AuthError.networkError.isRetryable == true)
        
        // Other errors should not be retryable
        #expect(AuthError.invalidCredentials.isRetryable == false)
        #expect(AuthError.emailNotConfirmed.isRetryable == false)
        #expect(AuthError.userAlreadyExists.isRetryable == false)
        #expect(AuthError.weakPassword.isRetryable == false)
        #expect(AuthError.sessionExpired.isRetryable == false)
    }
    
    @Test("Rate limit error includes retry time")
    func rateLimitErrorTime() {
        let error = AuthError.rateLimited(retryAfter: 45)
        #expect(error.errorDescription?.contains("45") == true)
    }
}

// MARK: - AuthViewModel Unit Tests

@Suite("AuthViewModel Tests")
struct AuthViewModelTests {
    
    @Test("Initial state is login")
    @MainActor
    func initialState() async {
        let viewModel = AuthViewModel()
        #expect(viewModel.authState == .login)
        #expect(viewModel.isLoginMode == true)
        #expect(viewModel.isSignupMode == false)
    }
    
    @Test("Toggle mode switches between login and signup")
    @MainActor
    func toggleMode() async {
        let viewModel = AuthViewModel()
        
        // Start in login mode
        #expect(viewModel.isLoginMode == true)
        
        // Toggle to signup
        viewModel.toggleMode()
        #expect(viewModel.isSignupMode == true)
        #expect(viewModel.authState == .signup)
        
        // Toggle back to login
        viewModel.toggleMode()
        #expect(viewModel.isLoginMode == true)
        #expect(viewModel.authState == .login)
    }
    
    @Test("Form validation for login")
    @MainActor
    func loginFormValidation() async {
        let viewModel = AuthViewModel()
        
        // Empty form should be invalid
        #expect(viewModel.isFormValid == false)
        
        // Valid email but short password
        viewModel.email = "test@example.com"
        viewModel.password = "12345" // Too short
        #expect(viewModel.isFormValid == false)
        
        // Valid email and password
        viewModel.password = "123456"
        #expect(viewModel.isFormValid == true)
        
        // Invalid email format
        viewModel.email = "invalid-email"
        #expect(viewModel.isFormValid == false)
    }
    
    @Test("Form validation for signup")
    @MainActor
    func signupFormValidation() async {
        let viewModel = AuthViewModel()
        viewModel.transitionToSignup()
        
        // Empty form should be invalid
        #expect(viewModel.isFormValid == false)
        
        // Fill in all required fields
        viewModel.name = "Test User"
        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        viewModel.confirmPassword = "123456"
        #expect(viewModel.isFormValid == true)
        
        // Mismatched passwords
        viewModel.confirmPassword = "different"
        #expect(viewModel.isFormValid == false)
        
        // Empty name
        viewModel.confirmPassword = "123456"
        viewModel.name = "   " // Whitespace only
        #expect(viewModel.isFormValid == false)
    }
    
    @Test("Transition to awaiting verification state")
    @MainActor
    func transitionToAwaitingVerification() async {
        let viewModel = AuthViewModel()
        
        viewModel.transitionToAwaitingVerification(email: "test@example.com")
        
        #expect(viewModel.authState.isAwaitingVerification == true)
        #expect(viewModel.authState.email == "test@example.com")
    }
    
    @Test("Transition to verified awaiting login")
    @MainActor
    func transitionToVerifiedAwaitingLogin() async {
        let viewModel = AuthViewModel()
        
        viewModel.transitionToVerifiedAwaitingLogin(email: "test@example.com")
        
        #expect(viewModel.authState.isVerifiedAwaitingLogin == true)
        #expect(viewModel.email == "test@example.com")
        #expect(viewModel.showSuccess == true)
    }
    
    @Test("Clear form resets all fields")
    @MainActor
    func clearForm() async {
        let viewModel = AuthViewModel()
        
        // Fill in form
        viewModel.name = "Test"
        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        viewModel.confirmPassword = "123456"
        
        // Clear form
        viewModel.clearForm()
        
        #expect(viewModel.name.isEmpty)
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
    }
    
    @Test("Clear error resets error state")
    @MainActor
    func clearError() async {
        let viewModel = AuthViewModel()
        
        // Simulate an error
        viewModel.errorMessage = "Test error"
        viewModel.showError = true
        
        // Clear error
        viewModel.clearError()
        
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showError == false)
    }
    
    @Test("AuthMode computed properties")
    @MainActor
    func authModeProperties() async {
        let viewModel = AuthViewModel()
        
        // Login mode
        #expect(viewModel.primaryButtonTitle == "Sign In")
        #expect(viewModel.switchModePrompt == "Don't have an account?")
        #expect(viewModel.switchModeAction == "Sign Up")
        
        // Signup mode
        viewModel.transitionToSignup()
        #expect(viewModel.primaryButtonTitle == "Sign Up")
        #expect(viewModel.switchModePrompt == "Already have an account?")
        #expect(viewModel.switchModeAction == "Sign In")
    }
}

// MARK: - GuestModeService Tests

@Suite("GuestModeService Tests")
struct GuestModeServiceTests {
    
    @Test("Enable and disable guest mode")
    @MainActor
    func guestModeToggle() async {
        let service = GuestModeService.shared
        
        // Store original state to restore later
        let originalGuestMode = service.isGuestMode
        
        // Enable guest mode
        service.enableGuestMode()
        #expect(service.isGuestMode == true)
        
        // Should not sync to cloud in guest mode
        // Note: shouldSyncToCloud also checks AuthService.isAuthenticated
        // In guest mode, this should return false regardless
        #expect(service.shouldSyncToCloud() == false)
        
        // Disable guest mode
        service.disableGuestMode()
        #expect(service.isGuestMode == false)
        
        // Restore original state
        if originalGuestMode {
            service.enableGuestMode()
        }
    }
    
    @Test("Cloud feature guard shows prompt in guest mode")
    @MainActor
    func cloudFeatureGuard() async {
        let service = GuestModeService.shared
        
        // Enable guest mode
        service.enableGuestMode()
        
        // Try to use cloud feature
        let canUse = service.canUseCloudFeature("sync data")
        
        #expect(canUse == false)
        #expect(service.showAccountPrompt == true)
        #expect(service.accountPromptMessage.contains("sync data") == true)
        
        // Clean up
        service.showAccountPrompt = false
        service.disableGuestMode()
    }
}

// MARK: - DTO Conversion Tests

@Suite("DTO Conversion Tests")
struct DTOConversionTests {
    
    @Test("FridgeItemDTO converts correctly to and from FridgeItem")
    func fridgeItemDTOConversion() {
        let userId = UUID()
        let originalItem = FridgeItem(
            name: "Chicken",
            quantity: "2 lbs",
            category: "protein",
            isStaple: false
        )
        
        // Convert to DTO
        let dto = FridgeItemDTO(from: originalItem, userId: userId)
        
        #expect(dto.id == originalItem.id)
        #expect(dto.userId == userId)
        #expect(dto.name == originalItem.name)
        #expect(dto.quantity == originalItem.quantity)
        #expect(dto.category == originalItem.category)
        #expect(dto.isStaple == originalItem.isStaple)
        
        // Convert back to FridgeItem
        let convertedItem = dto.toFridgeItem()
        
        #expect(convertedItem.id == originalItem.id)
        #expect(convertedItem.name == originalItem.name)
        #expect(convertedItem.quantity == originalItem.quantity)
        #expect(convertedItem.category == originalItem.category)
        #expect(convertedItem.isStaple == originalItem.isStaple)
    }
    
    @Test("PantryItemDTO converts correctly to and from Ingredient")
    func pantryItemDTOConversion() {
        let userId = UUID()
        let originalItem = Ingredient(
            name: "Rice",
            quantity: "2",
            unit: "cups",
            isStaple: true
        )
        
        // Convert to DTO
        let dto = PantryItemDTO(from: originalItem, userId: userId)
        
        #expect(dto.id == originalItem.id)
        #expect(dto.userId == userId)
        #expect(dto.name == originalItem.name)
        #expect(dto.quantity == originalItem.quantity)
        #expect(dto.unit == originalItem.unit)
        #expect(dto.isStaple == originalItem.isStaple)
        
        // Convert back to Ingredient
        let convertedItem = dto.toIngredient()
        
        #expect(convertedItem.id == originalItem.id)
        #expect(convertedItem.name == originalItem.name)
        #expect(convertedItem.quantity == originalItem.quantity)
        #expect(convertedItem.unit == originalItem.unit)
        #expect(convertedItem.isStaple == originalItem.isStaple)
    }
    
    @Test("RecipeDTO converts correctly to and from Recipe")
    func recipeDTOConversion() {
        let userId = UUID()
        let originalRecipe = TestFixtures.testRecipe
        
        // Convert to DTO
        let dto = RecipeDTO(from: originalRecipe, userId: userId, isAiGenerated: true)
        
        #expect(dto.id == originalRecipe.id)
        #expect(dto.userId == userId)
        #expect(dto.title == originalRecipe.title)
        #expect(dto.description == originalRecipe.description)
        #expect(dto.prepTime == originalRecipe.prepTime)
        #expect(dto.cookTime == originalRecipe.cookTime)
        #expect(dto.calories == originalRecipe.macros.calories)
        #expect(dto.protein == originalRecipe.macros.protein)
        #expect(dto.carbs == originalRecipe.macros.carbs)
        #expect(dto.fats == originalRecipe.macros.fats)
        #expect(dto.ingredients == originalRecipe.ingredients)
        #expect(dto.steps == originalRecipe.steps)
        #expect(dto.isAiGenerated == true)
        
        // Convert back to Recipe
        let convertedRecipe = dto.toRecipe()
        
        #expect(convertedRecipe.id == originalRecipe.id)
        #expect(convertedRecipe.title == originalRecipe.title)
        #expect(convertedRecipe.description == originalRecipe.description)
        #expect(convertedRecipe.prepTime == originalRecipe.prepTime)
        #expect(convertedRecipe.cookTime == originalRecipe.cookTime)
        #expect(convertedRecipe.macros.calories == originalRecipe.macros.calories)
        #expect(convertedRecipe.macros.protein == originalRecipe.macros.protein)
    }
    
    @Test("DailyMacroLogDTO converts correctly")
    func dailyMacroLogDTOConversion() {
        let userId = UUID()
        var originalLog = DailyMacroLog()
        originalLog.caloriesConsumed = 1500
        originalLog.proteinConsumed = 100
        originalLog.carbsConsumed = 150
        originalLog.fatsConsumed = 50
        
        // Convert to DTO
        let dto = DailyMacroLogDTO(from: originalLog, userId: userId)
        
        #expect(dto.userId == userId)
        #expect(dto.caloriesConsumed == originalLog.caloriesConsumed)
        #expect(dto.proteinConsumed == originalLog.proteinConsumed)
        #expect(dto.carbsConsumed == originalLog.carbsConsumed)
        #expect(dto.fatsConsumed == originalLog.fatsConsumed)
        
        // Convert back
        let convertedLog = dto.toDailyMacroLog()
        
        #expect(convertedLog.caloriesConsumed == originalLog.caloriesConsumed)
        #expect(convertedLog.proteinConsumed == originalLog.proteinConsumed)
        #expect(convertedLog.carbsConsumed == originalLog.carbsConsumed)
        #expect(convertedLog.fatsConsumed == originalLog.fatsConsumed)
    }
    
    @Test("ChatSessionDTO converts correctly")
    func chatSessionDTOConversion() {
        let userId = UUID()
        let recipeId = UUID()
        let originalSession = ChatSession(
            title: "Test Chat",
            messages: [],
            createdAt: Date(),
            updatedAt: Date(),
            recipeId: recipeId
        )
        
        // Convert to DTO
        let dto = ChatSessionDTO(from: originalSession, userId: userId)
        
        #expect(dto.id == originalSession.id)
        #expect(dto.userId == userId)
        #expect(dto.recipeId == recipeId)
        #expect(dto.title == originalSession.title)
        
        // Convert back (messages are fetched separately)
        let convertedSession = dto.toChatSession()
        
        #expect(convertedSession.id == originalSession.id)
        #expect(convertedSession.title == originalSession.title)
        #expect(convertedSession.recipeId == recipeId)
        #expect(convertedSession.messages.isEmpty) // Messages fetched separately
    }
    
    @Test("ActivityFeedDTO converts correctly")
    func activityFeedDTOConversion() {
        let userId = UUID()
        let relatedId = UUID()
        let originalActivity = ActivityItem(
            type: .cookedRecipe,
            title: "Cooked Test Recipe",
            timestamp: Date(),
            relatedId: relatedId
        )
        
        // Convert to DTO
        let dto = ActivityFeedDTO(from: originalActivity, userId: userId)
        
        #expect(dto.id == originalActivity.id)
        #expect(dto.userId == userId)
        #expect(dto.activityType == originalActivity.type.rawValue)
        #expect(dto.title == originalActivity.title)
        #expect(dto.relatedId == relatedId)
        
        // Convert back
        let convertedActivity = dto.toActivityItem()
        
        #expect(convertedActivity != nil)
        #expect(convertedActivity?.id == originalActivity.id)
        #expect(convertedActivity?.type == originalActivity.type)
        #expect(convertedActivity?.title == originalActivity.title)
        #expect(convertedActivity?.relatedId == relatedId)
    }
    
    @Test("RecipeFeedbackDTO converts correctly")
    func recipeFeedbackDTOConversion() {
        let userId = UUID()
        let recipeId = UUID()
        let originalFeedback = RecipeFeedback(
            recipeId: recipeId,
            recipeName: "Test Recipe",
            rating: 4,
            enjoyed: true,
            comments: "Great recipe!"
        )
        
        // Convert to DTO
        let dto = RecipeFeedbackDTO(from: originalFeedback, userId: userId)
        
        #expect(dto.id == originalFeedback.id)
        #expect(dto.userId == userId)
        #expect(dto.recipeId == recipeId)
        #expect(dto.recipeName == originalFeedback.recipeName)
        #expect(dto.rating == originalFeedback.rating)
        #expect(dto.enjoyed == originalFeedback.enjoyed)
        #expect(dto.comments == originalFeedback.comments)
        
        // Convert back
        let convertedFeedback = dto.toRecipeFeedback()
        
        #expect(convertedFeedback.id == originalFeedback.id)
        #expect(convertedFeedback.recipeId == recipeId)
        #expect(convertedFeedback.recipeName == originalFeedback.recipeName)
        #expect(convertedFeedback.rating == originalFeedback.rating)
        #expect(convertedFeedback.enjoyed == originalFeedback.enjoyed)
    }
}

// MARK: - DataManager Tests

@Suite("DataManager Unit Tests")
struct DataManagerUnitTests {
    
    @Test("DailyMacroLog date string format")
    func dailyMacroLogDateFormat() {
        var log = DailyMacroLog()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expected = formatter.string(from: Date())
        
        #expect(log.dateString == expected)
    }
    
    @Test("DailyMacroLog isToday property")
    func dailyMacroLogIsToday() {
        var log = DailyMacroLog()
        #expect(log.isToday == true)
        
        // Set to yesterday
        log.date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        #expect(log.isToday == false)
    }
    
    @Test("Macro goals in grams calculation")
    @MainActor
    func macroGoalsInGrams() async {
        let dataManager = DataManager.shared
        
        // Set a known profile
        dataManager.userProfile = UserProfile(
            name: "Test",
            email: "test@example.com",
            dietaryPreferences: [],
            allergies: [],
            macroGoals: UserProfile.MacroGoals(
                dailyCalories: 2000,
                proteinPercentage: 30,
                carbsPercentage: 40,
                fatsPercentage: 30
            )
        )
        
        let goals = dataManager.macroGoalsInGrams
        
        // 2000 cal * 30% protein / 4 cal per g = 150g protein
        #expect(goals.protein == 150)
        // 2000 cal * 40% carbs / 4 cal per g = 200g carbs
        #expect(goals.carbs == 200)
        // 2000 cal * 30% fats / 9 cal per g = ~66g fats
        #expect(goals.fats == 66)
        #expect(goals.calories == 2000)
    }
    
    @Test("Recipe is favorite check")
    @MainActor
    func isFavoriteCheck() async {
        let dataManager = DataManager.shared
        let recipe = TestFixtures.testRecipe
        
        // Clear any existing favorites
        dataManager.resetFavorites()
        
        // Should not be favorite initially
        #expect(dataManager.isFavorite(recipe) == false)
        
        // Add as favorite
        dataManager.addFavorite(recipe)
        #expect(dataManager.isFavorite(recipe) == true)
        
        // Remove from favorites
        dataManager.removeFavorite(recipe)
        #expect(dataManager.isFavorite(recipe) == false)
    }
    
    @Test("Toggle favorite adds and removes recipe")
    @MainActor
    func toggleFavorite() async {
        let dataManager = DataManager.shared
        let recipe = TestFixtures.testRecipe
        
        // Clear any existing favorites
        dataManager.resetFavorites()
        
        // Toggle on
        dataManager.toggleFavorite(recipe)
        #expect(dataManager.isFavorite(recipe) == true)
        
        // Toggle off
        dataManager.toggleFavorite(recipe)
        #expect(dataManager.isFavorite(recipe) == false)
    }
    
    @Test("Has favorites property")
    @MainActor
    func hasFavorites() async {
        let dataManager = DataManager.shared
        
        // Clear favorites
        dataManager.resetFavorites()
        #expect(dataManager.hasFavorites == false)
        
        // Add a favorite
        dataManager.addFavorite(TestFixtures.testRecipe)
        #expect(dataManager.hasFavorites == true)
        
        // Clean up
        dataManager.resetFavorites()
    }
    
    @Test("Find duplicates in fridge items")
    @MainActor
    func findDuplicates() async {
        let dataManager = DataManager.shared
        
        // Clear and add initial items
        dataManager.clearAllFridgeItems()
        let existingItem = FridgeItem(name: "Chicken", quantity: "1 lb", category: "protein")
        dataManager.addFridgeItem(existingItem)
        
        // Create new items with one duplicate
        let newItems = [
            FridgeItem(name: "Chicken", quantity: "2 lbs", category: "protein"),
            FridgeItem(name: "Milk", quantity: "1 gallon", category: "dairy")
        ]
        
        let duplicates = dataManager.findDuplicates(newItems: newItems)
        
        #expect(duplicates.count == 1)
        #expect(duplicates.first?.existingItem.name.lowercased() == "chicken")
        #expect(duplicates.first?.newItem.name.lowercased() == "chicken")
        
        // Clean up
        dataManager.clearAllFridgeItems()
    }
}

// MARK: - Update DTO Tests

@Suite("Update DTO Tests")
struct UpdateDTOTests {
    
    @Test("ProfileUpdateDTO encodes correctly")
    func profileUpdateDTOEncoding() throws {
        let dto = ProfileUpdateDTO(name: "New Name", avatarUrl: "https://example.com/avatar.jpg")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("name"))
        #expect(json.contains("New Name"))
        #expect(json.contains("avatar_url"))
    }
    
    @Test("UserPreferencesUpdateDTO encodes correctly")
    func userPreferencesUpdateDTOEncoding() throws {
        let dto = UserPreferencesUpdateDTO(
            dietaryPreferences: ["Vegetarian", "Gluten-Free"],
            allergies: ["Peanuts"],
            dailyCalories: 2000,
            proteinPercentage: 30,
            carbsPercentage: 40,
            fatsPercentage: 30,
            hasMacroGoals: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("dietary_preferences"))
        #expect(json.contains("daily_calories"))
        #expect(json.contains("protein_percentage"))
    }
    
    @Test("ChatSessionInsertDTO encodes correctly")
    func chatSessionInsertDTOEncoding() throws {
        let userId = UUID()
        let recipeId = UUID()
        let dto = ChatSessionInsertDTO(userId: userId, recipeId: recipeId, title: "Test Chat")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("user_id"))
        #expect(json.contains("recipe_id"))
        #expect(json.contains("title"))
    }
}

// MARK: - Integration Flow Tests (Require Supabase Connection)

/// These tests require a valid Supabase connection and test credentials.
/// They are marked with a custom tag and can be run separately.
@Suite("Integration Flow Tests", .tags(.integration))
struct IntegrationFlowTests {
    
    /// Test the complete signup -> data sync flow
    /// Note: This test requires valid Supabase credentials configured
    @Test("Full signup and data sync flow", .disabled("Requires valid Supabase credentials"))
    @MainActor
    func fullSignupAndDataSyncFlow() async throws {
        // This test would verify:
        // 1. User signs up successfully
        // 2. Email verification is sent
        // 3. After verification, user can sign in
        // 4. Local data syncs to cloud
        // 5. User can sign out and back in
        // 6. Data loads from cloud correctly
        
        // Note: In a real implementation, you would:
        // 1. Create a test user with a unique email
        // 2. Use Supabase's test mode or a dedicated test project
        // 3. Clean up test data after the test
    }
    
    /// Test data persistence across sessions
    @Test("Data persists after logout and login", .disabled("Requires valid Supabase credentials"))
    @MainActor
    func dataPersistenceAcrossSessions() async throws {
        // This test would verify:
        // 1. User is logged in
        // 2. User adds fridge items, pantry items, favorites
        // 3. User logs out
        // 4. User logs back in
        // 5. All data is restored from cloud
    }
    
    /// Test guest mode doesn't sync
    @Test("Guest mode does not sync to cloud")
    @MainActor
    func guestModeNoSync() async throws {
        let guestService = GuestModeService.shared
        
        // Enable guest mode
        guestService.enableGuestMode()
        
        // Verify no sync should happen
        #expect(guestService.shouldSyncToCloud() == false)
        
        // Verify cloud features are blocked
        let canUseCloud = guestService.canUseCloudFeature("sync data")
        #expect(canUseCloud == false)
        
        // Clean up
        guestService.disableGuestMode()
        guestService.showAccountPrompt = false
    }
}

// MARK: - Test Tags

extension Tag {
    /// Tests that require Supabase integration
    @Tag static var integration: Self
}

// MARK: - ChatMessage Extension for Testing

/// Helper to create test chat messages
extension ChatMessage {
    static func testMessage(isUser: Bool = true, text: String = "Test message") -> ChatMessage {
        ChatMessage(
            content: .text(text),
            isUser: isUser
        )
    }
}

// MARK: - UserProfile Extension for Testing

extension UserProfile: Equatable {
    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.email == rhs.email &&
        lhs.dietaryPreferences == rhs.dietaryPreferences &&
        lhs.allergies == rhs.allergies &&
        lhs.hasMacroGoals == rhs.hasMacroGoals
    }
}

// MARK: - Sync State Tests

@Suite("Sync State Tests")
struct SyncStateTests {
    
    @Test("DataManager sync state properties initialize correctly")
    @MainActor
    func syncStateInitialization() async {
        let dataManager = DataManager.shared
        
        // Initial state should be not syncing
        #expect(dataManager.isSyncing == false)
        #expect(dataManager.isLoadingFromCloud == false)
        #expect(dataManager.syncError == nil)
    }
    
    @Test("Clear sync error works")
    @MainActor
    func clearSyncError() async {
        let dataManager = DataManager.shared
        
        // Simulate an error
        dataManager.syncError = "Test error"
        #expect(dataManager.syncError != nil)
        
        // Clear it
        dataManager.clearSyncError()
        #expect(dataManager.syncError == nil)
    }
}

// MARK: - AuthState Tests

@Suite("AuthState Enum Tests")
struct AuthStateEnumTests {
    
    @Test("AuthState isLoginOrSignup property")
    func isLoginOrSignup() {
        #expect(AuthState.login.isLoginOrSignup == true)
        #expect(AuthState.signup.isLoginOrSignup == true)
        #expect(AuthState.awaitingEmailVerification(email: "test@example.com").isLoginOrSignup == false)
        #expect(AuthState.verifiedAwaitingLogin(email: "test@example.com").isLoginOrSignup == false)
    }
    
    @Test("AuthState isAwaitingVerification property")
    func isAwaitingVerification() {
        #expect(AuthState.login.isAwaitingVerification == false)
        #expect(AuthState.signup.isAwaitingVerification == false)
        #expect(AuthState.awaitingEmailVerification(email: "test@example.com").isAwaitingVerification == true)
        #expect(AuthState.verifiedAwaitingLogin(email: "test@example.com").isAwaitingVerification == false)
    }
    
    @Test("AuthState isVerifiedAwaitingLogin property")
    func isVerifiedAwaitingLogin() {
        #expect(AuthState.login.isVerifiedAwaitingLogin == false)
        #expect(AuthState.signup.isVerifiedAwaitingLogin == false)
        #expect(AuthState.awaitingEmailVerification(email: "test@example.com").isVerifiedAwaitingLogin == false)
        #expect(AuthState.verifiedAwaitingLogin(email: "test@example.com").isVerifiedAwaitingLogin == true)
    }
    
    @Test("AuthState email property")
    func emailProperty() {
        #expect(AuthState.login.email == nil)
        #expect(AuthState.signup.email == nil)
        #expect(AuthState.awaitingEmailVerification(email: "test@example.com").email == "test@example.com")
        #expect(AuthState.verifiedAwaitingLogin(email: "verified@example.com").email == "verified@example.com")
    }
}

// MARK: - AuthMode Tests

@Suite("AuthMode Enum Tests")
struct AuthModeEnumTests {
    
    @Test("AuthMode raw values")
    func rawValues() {
        #expect(AuthMode.login.rawValue == "Sign In")
        #expect(AuthMode.signup.rawValue == "Sign Up")
    }
    
    @Test("AuthMode all cases")
    func allCases() {
        #expect(AuthMode.allCases.count == 2)
        #expect(AuthMode.allCases.contains(.login))
        #expect(AuthMode.allCases.contains(.signup))
    }
}
