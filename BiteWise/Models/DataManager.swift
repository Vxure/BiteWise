import Foundation
import SwiftUI
import os.log

// MARK: - Data Manager for Local Persistence with Cloud Sync
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - Privacy-Safe Logger
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BiteWise", category: "DataManager")
    
    // MARK: - Published Data Properties
    @Published var userProfile: UserProfile
    @Published var pantryItems: [Ingredient]
    @Published var recipeHistory: [Recipe]
    @Published var dailyMacros: DailyMacroLog
    @Published var cookedRecipeIDs: Set<UUID>
    @Published var recipeRatings: [UUID: Int]
    @Published var fridgeItems: [FridgeItem]
    @Published var lastFridgeScanDate: Date?
    @Published var activityLog: [ActivityItem]
    @Published var lastPantryUpdateDate: Date?
    @Published var favoriteRecipes: [Recipe]
    @Published var generalChatHistory: [ChatMessage]
    @Published var recipeChatHistories: [UUID: [ChatMessage]]
    @Published var macroHistory: [DailyMacroLog]
    @Published var recipeFeedback: [RecipeFeedback]
    @Published var chatSessions: [ChatSession]
    
    // MARK: - Sync State Properties
    @Published var isSyncing: Bool = false
    @Published var syncError: String?
    @Published var lastSyncDate: Date?
    @Published var isLoadingFromCloud: Bool = false
    
    private let userProfileKey = "userProfile"
    private static let userProfileKeychainKey = "userProfile"
    private static let dataVersionKey = "dataVersion"
    private static let currentDataVersion = 1
    private let pantryItemsKey = "pantryItems"
    private let recipeHistoryKey = "recipeHistory"
    private let dailyMacrosKey = "dailyMacros"
    private let cookedRecipesKey = "cookedRecipeIDs"
    private let recipeRatingsKey = "recipeRatings"
    private let fridgeItemsKey = "fridgeItems"
    private let lastFridgeScanDateKey = "lastFridgeScanDate"
    private let activityLogKey = "activityLog"
    private let lastPantryUpdateDateKey = "lastPantryUpdateDate"
    private let favoriteRecipesKey = "favoriteRecipes"
    private let generalChatHistoryKey = "generalChatHistory"
    private let recipeChatHistoriesKey = "recipeChatHistories"
    private let macroHistoryKey = "macroHistory"
    private let recipeFeedbackKey = "recipeFeedback"
    private let chatSessionsKey = "chatSessions"
    
    /// Maximum number of activities to keep in the log
    private let maxActivityLogSize = 50
    
    private init() {
        DataManager.applyDataVersioning()
        // Load saved data or use defaults
        // Note: pantryItems defaults to empty array - users set up pantry during onboarding
        self.userProfile = DataManager.loadUserProfile() ?? UserProfile.dummy
        self.pantryItems = DataManager.loadPantryItems() ?? []
        self.recipeHistory = DataManager.loadRecipeHistory() ?? []
        self.dailyMacros = DataManager.loadDailyMacros() ?? DailyMacroLog()
        self.cookedRecipeIDs = DataManager.loadCookedRecipes()
        self.recipeRatings = DataManager.loadRecipeRatings()
        self.fridgeItems = DataManager.loadFridgeItems()
        self.lastFridgeScanDate = DataManager.loadLastFridgeScanDate()
        self.activityLog = DataManager.loadActivityLog()
        self.lastPantryUpdateDate = DataManager.loadLastPantryUpdateDate()
        self.favoriteRecipes = DataManager.loadFavoriteRecipes()
        self.generalChatHistory = DataManager.loadGeneralChatHistory()
        self.recipeChatHistories = DataManager.loadRecipeChatHistories()
        self.macroHistory = DataManager.loadMacroHistory()
        self.recipeFeedback = DataManager.loadRecipeFeedback()
        self.chatSessions = DataManager.loadChatSessions()
        
        // Check and clear expired fridge items on launch
        clearExpiredFridgeItemsIfNeeded()
        
        // Check and clear expired chat histories on launch
        clearExpiredChatHistories()
        
        // Check and clear expired chat sessions on launch
        clearExpiredChatSessions()
    }

    // MARK: - Data Versioning
    private static func applyDataVersioning() {
        let storedVersion = UserDefaults.standard.integer(forKey: dataVersionKey)
        guard storedVersion != currentDataVersion else { return }
        DataManager.logger.info("Data version mismatch (stored=\(storedVersion), current=\(currentDataVersion)). No destructive migration applied.")
        UserDefaults.standard.set(currentDataVersion, forKey: dataVersionKey)
    }

    // MARK: - UserDefaults Helpers
    private func saveCodable<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let encoded = try JSONEncoder().encode(value)
            UserDefaults.standard.set(encoded, forKey: key)
        } catch {
            DataManager.logger.error("Failed to encode \(key): \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func loadCodable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            DataManager.logger.error("Failed to decode \(key): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    // MARK: - User Profile
    func saveUserProfile() {
        do {
            try KeychainService.shared.saveCodable(userProfile, for: DataManager.userProfileKeychainKey)
        } catch {
            DataManager.logger.error("Failed to save user profile to Keychain: \(error.localizedDescription, privacy: .public)")
        }
        // Sync to cloud in background
        syncUserProfileToCloud()
    }
    
    /// Reset user identity fields (name/email) without clearing onboarding data.
    /// Used when entering guest mode to prevent showing previous user's info
    /// while preserving pantry items, macro goals, dietary preferences, etc.
    func resetUserIdentity() {
        userProfile.name = ""
        userProfile.email = ""
        saveUserProfile()
    }
    
    private static func loadUserProfile() -> UserProfile? {
        do {
            if let profile = try KeychainService.shared.loadCodable(UserProfile.self, for: DataManager.userProfileKeychainKey) {
                return profile
            }
        } catch {
            DataManager.logger.error("Failed to load user profile from Keychain: \(error.localizedDescription, privacy: .public)")
        }

        guard let profile = loadCodable(UserProfile.self, forKey: "userProfile") else {
            return nil
        }

        do {
            try KeychainService.shared.saveCodable(profile, for: DataManager.userProfileKeychainKey)
            UserDefaults.standard.removeObject(forKey: "userProfile")
        } catch {
            DataManager.logger.error("Failed to migrate user profile to Keychain: \(error.localizedDescription, privacy: .public)")
        }

        return profile
    }
    
    // MARK: - Pantry Items
    func savePantryItems() {
        saveCodable(pantryItems, forKey: pantryItemsKey)
        // Update the last pantry update date
        lastPantryUpdateDate = Date()
        saveLastPantryUpdateDate()
    }
    
    private static func loadPantryItems() -> [Ingredient]? {
        return loadCodable([Ingredient].self, forKey: "pantryItems")
    }
    
    func saveLastPantryUpdateDate() {
        if let date = lastPantryUpdateDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastPantryUpdateDateKey)
        }
    }
    
    private static func loadLastPantryUpdateDate() -> Date? {
        let interval = UserDefaults.standard.double(forKey: "lastPantryUpdateDate")
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
    
    /// Human-readable string for when the pantry was last updated
    var lastPantryUpdateTimeAgo: String? {
        guard let date = lastPantryUpdateDate else { return nil }
        return TimeFormatter.timeAgo(from: date)
    }
    
    func addPantryItem(_ item: Ingredient) {
        pantryItems.append(item)
        savePantryItems()
        
        // Log activity
        logActivity(.addedPantryItem(item))
        
        // Sync to cloud in background
        syncPantryItemToCloud(item)
    }
    
    func removePantryItem(_ item: Ingredient) {
        pantryItems.removeAll { $0.id == item.id }
        savePantryItems()
        
        // Sync deletion to cloud in background
        syncPantryItemDeletionToCloud(item.id)
    }
    
    // MARK: - Recipe History
    func saveRecipeHistory() {
        saveCodable(recipeHistory, forKey: recipeHistoryKey)
    }
    
    private static func loadRecipeHistory() -> [Recipe]? {
        return loadCodable([Recipe].self, forKey: "recipeHistory")
    }
    
    func addRecipeToHistory(_ recipe: Recipe) {
        // Add to beginning of array (most recent first)
        recipeHistory.insert(recipe, at: 0)
        // Keep only last 20 recipes
        if recipeHistory.count > 20 {
            recipeHistory = Array(recipeHistory.prefix(20))
        }
        saveRecipeHistory()
    }
    
    // MARK: - Daily Macros
    func saveDailyMacros() {
        saveCodable(dailyMacros, forKey: dailyMacrosKey)
        // Sync to cloud in background
        syncDailyMacrosToCloud()
    }
    
    private static func loadDailyMacros() -> DailyMacroLog? {
        return loadCodable(DailyMacroLog.self, forKey: "dailyMacros")
    }
    
    func updateDailyMacros(calories: Int, protein: Double, carbs: Double, fats: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Reset if it's a new day - archive yesterday's log first
        if !Calendar.current.isDate(dailyMacros.date, inSameDayAs: today) {
            archiveDailyMacros()
            dailyMacros = DailyMacroLog()
        }
        
        dailyMacros.caloriesConsumed += calories
        dailyMacros.proteinConsumed += protein
        dailyMacros.carbsConsumed += carbs
        dailyMacros.fatsConsumed += fats
        
        saveDailyMacros()
    }
    
    /// Archive the current daily macros to history before resetting
    private func archiveDailyMacros() {
        // Only archive if there's meaningful data
        guard dailyMacros.caloriesConsumed > 0 else { return }
        
        // Remove any existing entry for this date
        macroHistory.removeAll { $0.dateString == dailyMacros.dateString }
        
        // Add to history
        macroHistory.append(dailyMacros)
        
        // Keep only last 30 days
        if macroHistory.count > 30 {
            macroHistory = Array(macroHistory.suffix(30))
        }
        
        // Sort by date (oldest first)
        macroHistory.sort { $0.date < $1.date }
        
        saveMacroHistory()
    }
    
    // MARK: - Macro History
    
    func saveMacroHistory() {
        saveCodable(macroHistory, forKey: macroHistoryKey)
    }
    
    private static func loadMacroHistory() -> [DailyMacroLog] {
        return loadCodable([DailyMacroLog].self, forKey: "macroHistory") ?? []
    }
    
    /// Get macro logs for the last N days (including today)
    func getRecentMacroLogs(days: Int = 7) -> [DailyMacroLog] {
        var logs: [DailyMacroLog] = []
        let calendar = Calendar.current
        
        // Start from (days-1) days ago to today
        for dayOffset in (-(days-1)...0).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetDateString = formatter.string(from: targetDate)
            
            // Check if today
            if calendar.isDateInToday(targetDate) {
                logs.append(dailyMacros)
            } else if let historicalLog = macroHistory.first(where: { $0.dateString == targetDateString }) {
                logs.append(historicalLog)
            } else {
                // No data for this day - create empty entry
                var emptyLog = DailyMacroLog()
                emptyLog.date = targetDate
                logs.append(emptyLog)
            }
        }
        
        return logs
    }
    
    /// Calculate the current streak (consecutive days with logged macros)
    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        
        // Check today first
        if dailyMacros.caloriesConsumed > 0 {
            streak = 1
        } else {
            return 0
        }
        
        // Check previous days
        for dayOffset in 1...30 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { break }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetDateString = formatter.string(from: targetDate)
            
            if let log = macroHistory.first(where: { $0.dateString == targetDateString }),
               log.caloriesConsumed > 0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Calculate macro goals in grams based on user profile
    var macroGoalsInGrams: (calories: Int, protein: Int, carbs: Int, fats: Int) {
        let profile = userProfile
        let calories = profile.macroGoals.dailyCalories
        let proteinG = Int((Double(calories) * profile.macroGoals.proteinPercentage / 100) / 4)
        let carbsG = Int((Double(calories) * profile.macroGoals.carbsPercentage / 100) / 4)
        let fatsG = Int((Double(calories) * profile.macroGoals.fatsPercentage / 100) / 9)
        return (calories, proteinG, carbsG, fatsG)
    }
    
    // MARK: - Cooked Recipes
    func saveCookedRecipes() {
        let idStrings = cookedRecipeIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: cookedRecipesKey)
    }
    
    private static func loadCookedRecipes() -> Set<UUID> {
        guard let idStrings = UserDefaults.standard.stringArray(forKey: "cookedRecipeIDs") else {
            return []
        }
        return Set(idStrings.compactMap { UUID(uuidString: $0) })
    }
    
    func isCooked(_ recipe: Recipe) -> Bool {
        cookedRecipeIDs.contains(recipe.id)
    }
    
    func toggleCooked(_ recipe: Recipe) {
        if cookedRecipeIDs.contains(recipe.id) {
            cookedRecipeIDs.remove(recipe.id)
            // Note: We don't subtract macros when unmarking as cooked
            // This is intentional - consumed calories shouldn't be "undone"
        } else {
            cookedRecipeIDs.insert(recipe.id)
            logActivity(.cookedRecipe(recipe))
            
            // Add recipe macros to daily totals
            addRecipeMacros(recipe)
            
            // Add to recipe history if not already there (for "Recently Cooked" display)
            if !recipeHistory.contains(where: { $0.id == recipe.id }) {
                addRecipeToHistory(recipe)
            }
        }
        saveCookedRecipes()
    }
    
    func markAsCooked(_ recipe: Recipe) {
        // Only add macros if this is the first time marking as cooked today
        let wasAlreadyCooked = cookedRecipeIDs.contains(recipe.id)
        
        cookedRecipeIDs.insert(recipe.id)
        saveCookedRecipes()
        
        // Log activity
        logActivity(.cookedRecipe(recipe))
        
        // Add recipe macros to daily totals (only if not already marked)
        if !wasAlreadyCooked {
            addRecipeMacros(recipe)
            
            // Add to recipe history if not already there (for "Recently Cooked" display)
            if !recipeHistory.contains(where: { $0.id == recipe.id }) {
                addRecipeToHistory(recipe)
            }
        }
    }
    
    func unmarkAsCooked(_ recipe: Recipe) {
        cookedRecipeIDs.remove(recipe.id)
        saveCookedRecipes()
        // Note: We don't subtract macros - consumed food stays consumed
    }
    
    /// Add a recipe's macros to the daily totals
    private func addRecipeMacros(_ recipe: Recipe) {
        updateDailyMacros(
            calories: recipe.macros.calories,
            protein: recipe.macros.protein,
            carbs: recipe.macros.carbs,
            fats: recipe.macros.fats
        )
    }
    
    // MARK: - Ingredient Deduction
    
    /// Deduct ingredients from inventory when a recipe is marked as cooked
    /// - Parameter recipe: The recipe that was cooked
    /// - Returns: Array of ingredient names that were removed from inventory
    /// Note: Staple items (isStaple == true) are NOT deducted - they are assumed to always be available
    @discardableResult
    func deductIngredients(for recipe: Recipe) -> [String] {
        var removedItems: [String] = []
        
        for ingredientString in recipe.ingredients {
            // Extract the main ingredient name from the string
            let name = parseIngredientName(from: ingredientString)
            
            // Check fridge items first
            if let index = fridgeItems.firstIndex(where: { 
                $0.name.lowercased().contains(name.lowercased()) ||
                name.lowercased().contains($0.name.lowercased())
            }) {
                let item = fridgeItems[index]
                // Skip staple items - they don't get deducted
                if !item.isStaple {
                    removedItems.append(item.name)
                    fridgeItems.remove(at: index)
                }
            }
            // Then check pantry items
            else if let index = pantryItems.firstIndex(where: { 
                $0.name.lowercased().contains(name.lowercased()) ||
                name.lowercased().contains($0.name.lowercased())
            }) {
                let item = pantryItems[index]
                // Skip staple items - they don't get deducted (pantry items are staples by default)
                if !item.isStaple {
                    removedItems.append(item.name)
                    pantryItems.remove(at: index)
                }
            }
        }
        
        // Save changes if any items were removed
        if !removedItems.isEmpty {
            saveFridgeItems()
            savePantryItems()
        }
        
        return removedItems
    }
    
    /// Parse an ingredient string to extract the main ingredient name
    /// Examples: "2 chicken breasts" -> "chicken", "1 cup spinach" -> "spinach"
    private func parseIngredientName(from ingredientString: String) -> String {
        // Common measurement words to skip
        let measurementWords = Set([
            "cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
            "oz", "ounce", "ounces", "lb", "pound", "pounds", "g", "gram", "grams",
            "kg", "kilogram", "ml", "liter", "liters", "pinch", "dash", "slice", "slices",
            "piece", "pieces", "clove", "cloves", "bunch", "can", "cans", "package", "packages",
            "large", "small", "medium", "fresh", "dried", "chopped", "minced", "diced",
            "sliced", "grated", "shredded", "to", "taste", "for", "garnish", "optional"
        ])
        
        // Split the string and filter out numbers and measurement words
        let words = ingredientString
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .filter { word in
                // Filter out numbers
                if Double(word) != nil { return false }
                // Filter out measurement words
                if measurementWords.contains(word) { return false }
                // Keep words with 2+ characters
                return word.count >= 2
            }
        
        // Return the first meaningful word, or the whole string if parsing fails
        return words.first ?? ingredientString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Recipe Ratings
    func saveRecipeRatings() {
        // Convert UUID keys to strings for storage
        let stringKeyedRatings = Dictionary(uniqueKeysWithValues: recipeRatings.map { ($0.key.uuidString, $0.value) })
        UserDefaults.standard.set(stringKeyedRatings, forKey: recipeRatingsKey)
    }
    
    private static func loadRecipeRatings() -> [UUID: Int] {
        guard let stringKeyedRatings = UserDefaults.standard.dictionary(forKey: "recipeRatings") as? [String: Int] else {
            return [:]
        }
        // Convert string keys back to UUIDs
        var ratings: [UUID: Int] = [:]
        for (key, value) in stringKeyedRatings {
            if let uuid = UUID(uuidString: key) {
                ratings[uuid] = value
            }
        }
        return ratings
    }
    
    func getRating(for recipe: Recipe) -> Int {
        recipeRatings[recipe.id] ?? 0
    }
    
    func setRating(for recipe: Recipe, rating: Int) {
        recipeRatings[recipe.id] = rating
        saveRecipeRatings()
        
        // Log activity (only if rating is positive)
        if rating > 0 {
            logActivity(.ratedRecipe(recipe, rating: rating))
        }
    }
    
    // MARK: - Fridge Items
    
    func saveFridgeItems() {
        saveCodable(fridgeItems, forKey: fridgeItemsKey)
    }
    
    private static func loadFridgeItems() -> [FridgeItem] {
        return loadCodable([FridgeItem].self, forKey: "fridgeItems") ?? []
    }
    
    func saveLastFridgeScanDate() {
        if let date = lastFridgeScanDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastFridgeScanDateKey)
        }
    }
    
    private static func loadLastFridgeScanDate() -> Date? {
        let interval = UserDefaults.standard.double(forKey: "lastFridgeScanDate")
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
    
    /// Add a single fridge item
    func addFridgeItem(_ item: FridgeItem) {
        fridgeItems.append(item)
        saveFridgeItems()
        
        // Log activity
        logActivity(.addedFridgeItem(item))
        
        // Sync to cloud in background
        syncFridgeItemToCloud(item)
    }
    
    /// Add multiple fridge items at once (e.g., from a scan)
    func addFridgeItems(_ items: [FridgeItem]) {
        fridgeItems.append(contentsOf: items)
        lastFridgeScanDate = Date()
        saveFridgeItems()
        saveLastFridgeScanDate()
        
        // Log activity for each item (limit to first 3 to avoid spam)
        for item in items.prefix(3) {
            logActivity(.addedFridgeItem(item))
        }
    }
    
    /// Replace all fridge items with new scan results
    func replaceFridgeItems(with items: [FridgeItem]) {
        fridgeItems = items
        lastFridgeScanDate = Date()
        saveFridgeItems()
        saveLastFridgeScanDate()
    }
    
    /// Remove a single fridge item
    func removeFridgeItem(_ item: FridgeItem) {
        fridgeItems.removeAll { $0.id == item.id }
        saveFridgeItems()
        
        // Sync deletion to cloud in background
        syncFridgeItemDeletionToCloud(item.id)
    }
    
    /// Remove fridge item by ID
    func removeFridgeItem(withId id: UUID) {
        fridgeItems.removeAll { $0.id == id }
        saveFridgeItems()
        
        // Sync deletion to cloud in background
        syncFridgeItemDeletionToCloud(id)
    }
    
    /// Clear all fridge items
    func clearAllFridgeItems() {
        fridgeItems.removeAll()
        lastFridgeScanDate = nil
        saveFridgeItems()
        UserDefaults.standard.removeObject(forKey: lastFridgeScanDateKey)
        
        // Sync to cloud in background
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            try? await SupabaseDataService.shared.deleteAllFridgeItems()
        }
    }
    
    /// Clear expired fridge items based on app settings
    func clearExpiredFridgeItemsIfNeeded() {
        let settings = AppSettings.shared
        guard settings.fridgeAutoExpireEnabled else { return }
        
        let expiryDays = settings.fridgeAutoExpireDays
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -expiryDays, to: Date()) ?? Date()
        
        let originalCount = fridgeItems.count
        fridgeItems.removeAll { $0.dateAdded < cutoffDate }
        
        // Only save if items were removed
        if fridgeItems.count != originalCount {
            saveFridgeItems()
        }
    }
    
    /// Get fridge items sorted by date added (newest first)
    var fridgeItemsSortedByDate: [FridgeItem] {
        fridgeItems.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    /// Get fridge items grouped by category
    var fridgeItemsByCategory: [String: [FridgeItem]] {
        Dictionary(grouping: fridgeItems, by: { $0.category })
    }
    
    /// Human-readable string for when the fridge was last scanned
    var lastFridgeScanTimeAgo: String? {
        guard let date = lastFridgeScanDate else { return nil }
        return TimeFormatter.timeAgo(from: date)
    }
    
    /// Check if fridge has items
    var hasFridgeItems: Bool {
        !fridgeItems.isEmpty
    }
    
    // MARK: - Smart Merge for Fridge Items
    
    /// Find duplicates between existing fridge items and new items
    /// - Parameter newItems: The new items from a scan
    /// - Returns: Array of DuplicateItem objects representing conflicts
    func findDuplicates(newItems: [FridgeItem]) -> [DuplicateItem] {
        var duplicates: [DuplicateItem] = []
        
        for newItem in newItems {
            if let existing = fridgeItems.first(where: { 
                $0.name.lowercased() == newItem.name.lowercased() 
            }) {
                duplicates.append(DuplicateItem(existingItem: existing, newItem: newItem))
            }
        }
        
        return duplicates
    }
    
    /// Apply smart merge with resolved duplicates
    /// - Parameters:
    ///   - newItems: All new items from the scan
    ///   - duplicateResolutions: Resolved duplicate items with user choices
    func smartMergeFridgeItems(newItems: [FridgeItem], duplicateResolutions: [DuplicateItem]) {
        // Build a set of existing item names that are being handled
        let duplicateNewNames = Set(duplicateResolutions.map { $0.newItem.name.lowercased() })
        
        // Process each resolution
        for duplicate in duplicateResolutions {
            switch duplicate.resolution {
            case .keepExisting:
                // Keep existing, do nothing (item stays as is)
                break
                
            case .replace:
                // Remove existing, will add new item below
                fridgeItems.removeAll { $0.id == duplicate.existingItem.id }
                
            case .combine:
                // Remove existing, create combined item
                fridgeItems.removeAll { $0.id == duplicate.existingItem.id }
                
                // Try to combine quantities
                let combinedQuantity = combineQuantities(
                    existing: duplicate.existingItem.quantity,
                    new: duplicate.newItem.quantity
                )
                
                let combinedItem = FridgeItem(
                    name: duplicate.newItem.name,
                    quantity: combinedQuantity,
                    category: duplicate.newItem.category,
                    dateAdded: Date() // Use current date for combined item
                )
                fridgeItems.append(combinedItem)
            }
        }
        
        // Add new items that aren't duplicates
        let itemsToAdd = newItems.filter { newItem in
            !duplicateNewNames.contains(newItem.name.lowercased())
        }
        fridgeItems.append(contentsOf: itemsToAdd)
        
        // Add replaced items (from resolution)
        let replacedItems = duplicateResolutions
            .filter { $0.resolution == .replace }
            .map { $0.newItem }
        fridgeItems.append(contentsOf: replacedItems)
        
        // Update scan date and save
        lastFridgeScanDate = Date()
        saveFridgeItems()
        saveLastFridgeScanDate()
    }
    
    /// Attempt to combine two quantity strings
    /// - Parameters:
    ///   - existing: The existing quantity string
    ///   - new: The new quantity string
    /// - Returns: Combined quantity string
    private func combineQuantities(existing: String, new: String) -> String {
        // Try to extract numbers from both quantities
        let existingNumber = extractNumber(from: existing)
        let newNumber = extractNumber(from: new)
        
        if let existingNum = existingNumber, let newNum = newNumber {
            // Both have numbers, add them
            let total = existingNum + newNum
            
            // Try to preserve the unit from the new quantity
            let unit = extractUnit(from: new) ?? extractUnit(from: existing) ?? ""
            
            if total == floor(total) {
                return "\(Int(total))\(unit.isEmpty ? "" : " \(unit)")"
            } else {
                return String(format: "%.1f%@", total, unit.isEmpty ? "" : " \(unit)")
            }
        } else {
            // Can't combine numerically, just concatenate
            if existing.isEmpty { return new }
            if new.isEmpty { return existing }
            return "\(existing) + \(new)"
        }
    }
    
    /// Extract a number from a quantity string
    private func extractNumber(from quantity: String) -> Double? {
        let pattern = "([0-9]+\\.?[0-9]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: quantity, range: NSRange(quantity.startIndex..., in: quantity)),
              let range = Range(match.range(at: 1), in: quantity) else {
            return nil
        }
        return Double(quantity[range])
    }
    
    /// Extract a unit from a quantity string
    private func extractUnit(from quantity: String) -> String? {
        let pattern = "[0-9]+\\.?[0-9]*\\s*([a-zA-Z]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: quantity, range: NSRange(quantity.startIndex..., in: quantity)),
              let range = Range(match.range(at: 1), in: quantity) else {
            return nil
        }
        return String(quantity[range])
    }
    
    // MARK: - Activity Log
    
    func saveActivityLog() {
        saveCodable(activityLog, forKey: activityLogKey)
    }
    
    private static func loadActivityLog() -> [ActivityItem] {
        return loadCodable([ActivityItem].self, forKey: "activityLog") ?? []
    }
    
    /// Log a new activity to the activity log
    func logActivity(_ activity: ActivityItem) {
        // Insert at beginning (most recent first)
        activityLog.insert(activity, at: 0)
        
        // Trim to max size
        if activityLog.count > maxActivityLogSize {
            activityLog = Array(activityLog.prefix(maxActivityLogSize))
        }
        
        saveActivityLog()
        
        // Sync to cloud in background
        syncActivityToCloud(activity)
    }
    
    /// Get the most recent activities
    func recentActivities(limit: Int = 5) -> [ActivityItem] {
        Array(activityLog.prefix(limit))
    }
    
    /// Check if there are any activities
    var hasActivities: Bool {
        !activityLog.isEmpty
    }
    
    /// Clear all activities (for testing/reset)
    func clearActivityLog() {
        activityLog.removeAll()
        UserDefaults.standard.removeObject(forKey: activityLogKey)
    }
    
    // MARK: - Favorites
    
    func saveFavoriteRecipes() {
        saveCodable(favoriteRecipes, forKey: favoriteRecipesKey)
    }
    
    private static func loadFavoriteRecipes() -> [Recipe] {
        return loadCodable([Recipe].self, forKey: "favoriteRecipes") ?? []
    }
    
    /// Check if a recipe is favorited
    func isFavorite(_ recipe: Recipe) -> Bool {
        favoriteRecipes.contains { $0.id == recipe.id }
    }
    
    /// Toggle favorite status for a recipe
    func toggleFavorite(_ recipe: Recipe) {
        let wasFavorite = favoriteRecipes.contains { $0.id == recipe.id }
        
        if let index = favoriteRecipes.firstIndex(where: { $0.id == recipe.id }) {
            favoriteRecipes.remove(at: index)
        } else {
            favoriteRecipes.append(recipe)
            logActivity(.favoritedRecipe(recipe))
        }
        saveFavoriteRecipes()
        
        // Sync to cloud in background (now it's the opposite state)
        syncFavoriteToCloud(recipe, isFavorite: !wasFavorite)
    }
    
    /// Add a recipe to favorites
    func addFavorite(_ recipe: Recipe) {
        if !isFavorite(recipe) {
            favoriteRecipes.append(recipe)
            logActivity(.favoritedRecipe(recipe))
            saveFavoriteRecipes()
            
            // Sync to cloud in background
            syncFavoriteToCloud(recipe, isFavorite: true)
        }
    }
    
    /// Remove a recipe from favorites
    func removeFavorite(_ recipe: Recipe) {
        favoriteRecipes.removeAll { $0.id == recipe.id }
        saveFavoriteRecipes()
        
        // Sync to cloud in background
        syncFavoriteToCloud(recipe, isFavorite: false)
    }
    
    /// Check if there are any favorites
    var hasFavorites: Bool {
        !favoriteRecipes.isEmpty
    }
    
    /// Reset all favorites (useful for testing)
    func resetFavorites() {
        favoriteRecipes.removeAll()
        UserDefaults.standard.removeObject(forKey: favoriteRecipesKey)
    }
    
    // MARK: - Chat History
    
    func saveGeneralChatHistory() {
        saveCodable(generalChatHistory, forKey: generalChatHistoryKey)
    }
    
    private static func loadGeneralChatHistory() -> [ChatMessage] {
        return loadCodable([ChatMessage].self, forKey: "generalChatHistory") ?? []
    }
    
    func saveRecipeChatHistories() {
        // Convert UUID keys to strings for JSON encoding
        let stringKeyed = Dictionary(uniqueKeysWithValues: recipeChatHistories.map { ($0.key.uuidString, $0.value) })
        saveCodable(stringKeyed, forKey: recipeChatHistoriesKey)
    }
    
    private static func loadRecipeChatHistories() -> [UUID: [ChatMessage]] {
        guard let stringKeyed = loadCodable([String: [ChatMessage]].self, forKey: "recipeChatHistories") else {
            return [:]
        }
        // Convert string keys back to UUIDs
        var result: [UUID: [ChatMessage]] = [:]
        for (key, value) in stringKeyed {
            if let uuid = UUID(uuidString: key) {
                result[uuid] = value
            }
        }
        return result
    }
    
    /// Get chat history for a specific recipe
    func getChatHistory(for recipeId: UUID) -> [ChatMessage] {
        return recipeChatHistories[recipeId] ?? []
    }
    
    /// Update chat history for a specific recipe
    func updateChatHistory(for recipeId: UUID, messages: [ChatMessage]) {
        recipeChatHistories[recipeId] = messages
        saveRecipeChatHistories()
    }
    
    /// Add a message to the general chat history
    func addGeneralChatMessage(_ message: ChatMessage) {
        generalChatHistory.append(message)
        saveGeneralChatHistory()
    }
    
    /// Add a message to a recipe's chat history
    func addRecipeChatMessage(_ message: ChatMessage, for recipeId: UUID) {
        if recipeChatHistories[recipeId] == nil {
            recipeChatHistories[recipeId] = []
        }
        recipeChatHistories[recipeId]?.append(message)
        saveRecipeChatHistories()
    }
    
    /// Clear all chat histories (for testing/reset)
    func clearAllChatHistories() {
        generalChatHistory.removeAll()
        recipeChatHistories.removeAll()
        UserDefaults.standard.removeObject(forKey: generalChatHistoryKey)
        UserDefaults.standard.removeObject(forKey: recipeChatHistoriesKey)
    }
    
    /// Clear expired chat messages based on app settings
    func clearExpiredChatHistories() {
        let settings = AppSettings.shared
        guard settings.chatAutoExpireEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate cutoff date for general chat
        guard let generalCutoff = calendar.date(byAdding: .day, value: -settings.generalChatExpireDays, to: now) else { return }
        
        // Clear expired general chat messages
        let originalGeneralCount = generalChatHistory.count
        generalChatHistory.removeAll { $0.timestamp < generalCutoff }
        
        // Calculate cutoff date for recipe chats
        let recipeCutoff: Date
        if settings.keepRecipeChatsLonger {
            recipeCutoff = calendar.date(byAdding: .day, value: -settings.recipeChatExpireDays, to: now) ?? generalCutoff
        } else {
            recipeCutoff = generalCutoff // Same as general
        }
        
        // Clear expired recipe chat histories
        var recipesModified = false
        for (recipeId, messages) in recipeChatHistories {
            let filtered = messages.filter { $0.timestamp >= recipeCutoff }
            if filtered.isEmpty {
                recipeChatHistories.removeValue(forKey: recipeId)
                recipesModified = true
            } else if filtered.count != messages.count {
                recipeChatHistories[recipeId] = filtered
                recipesModified = true
            }
        }
        
        // Save only if changes were made
        if generalChatHistory.count != originalGeneralCount {
            saveGeneralChatHistory()
        }
        if recipesModified {
            saveRecipeChatHistories()
        }
    }
    
    // MARK: - Chat Sessions (Multi-conversation support)
    
    func saveChatSessions() {
        saveCodable(chatSessions, forKey: chatSessionsKey)
    }
    
    private static func loadChatSessions() -> [ChatSession] {
        return loadCodable([ChatSession].self, forKey: "chatSessions") ?? []
    }
    
    /// Create a new chat session
    /// - Parameters:
    ///   - title: Initial title (defaults to "New Chat")
    ///   - recipeId: Optional recipe ID for recipe-specific chats
    /// - Returns: The newly created chat session
    @discardableResult
    func createChatSession(title: String = "New Chat", recipeId: UUID? = nil) -> ChatSession {
        let session = ChatSession(
            title: title,
            messages: [],
            createdAt: Date(),
            updatedAt: Date(),
            recipeId: recipeId
        )
        chatSessions.insert(session, at: 0) // Add to beginning (most recent first)
        saveChatSessions()
        return session
    }
    
    /// Update an existing chat session
    /// - Parameter session: The session to update
    func updateChatSession(_ session: ChatSession) {
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index] = session
            saveChatSessions()
        }
    }
    
    /// Add a message to a chat session
    /// - Parameters:
    ///   - message: The message to add
    ///   - sessionId: The ID of the session to add the message to
    func addMessageToChatSession(_ message: ChatMessage, sessionId: UUID) {
        if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
            chatSessions[index].addMessage(message)
            // Move to top of list (most recent)
            let session = chatSessions.remove(at: index)
            chatSessions.insert(session, at: 0)
            saveChatSessions()
        }
    }
    
    /// Delete a chat session
    /// - Parameter sessionId: The ID of the session to delete
    func deleteChatSession(_ sessionId: UUID) {
        chatSessions.removeAll { $0.id == sessionId }
        saveChatSessions()
    }
    
    /// Get a chat session by ID
    /// - Parameter sessionId: The ID of the session to retrieve
    /// - Returns: The chat session, or nil if not found
    func getChatSession(_ sessionId: UUID) -> ChatSession? {
        chatSessions.first { $0.id == sessionId }
    }
    
    /// Get all general (non-recipe-specific) chat sessions
    var generalChatSessions: [ChatSession] {
        chatSessions.filter { $0.recipeId == nil }
    }
    
    /// Get chat sessions for a specific recipe
    /// - Parameter recipeId: The recipe ID to filter by
    /// - Returns: Array of chat sessions for that recipe
    func getChatSessions(for recipeId: UUID) -> [ChatSession] {
        chatSessions.filter { $0.recipeId == recipeId }
    }
    
    /// Check if there are any chat sessions
    var hasChatSessions: Bool {
        !chatSessions.isEmpty
    }
    
    /// Clear all chat sessions
    func clearAllChatSessions() {
        chatSessions.removeAll()
        UserDefaults.standard.removeObject(forKey: chatSessionsKey)
    }
    
    /// Clear expired chat sessions based on app settings
    func clearExpiredChatSessions() {
        let settings = AppSettings.shared
        guard settings.chatAutoExpireEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate cutoff dates
        guard let generalCutoff = calendar.date(byAdding: .day, value: -settings.generalChatExpireDays, to: now) else { return }
        
        let recipeCutoff: Date
        if settings.keepRecipeChatsLonger {
            recipeCutoff = calendar.date(byAdding: .day, value: -settings.recipeChatExpireDays, to: now) ?? generalCutoff
        } else {
            recipeCutoff = generalCutoff
        }
        
        let originalCount = chatSessions.count
        
        // Remove expired sessions
        chatSessions.removeAll { session in
            let cutoff = session.isRecipeChat ? recipeCutoff : generalCutoff
            return session.updatedAt < cutoff
        }
        
        // Save only if sessions were removed
        if chatSessions.count != originalCount {
            saveChatSessions()
        }
    }
    
    // MARK: - Recipe Feedback
    
    func saveRecipeFeedbackData() {
        saveCodable(recipeFeedback, forKey: recipeFeedbackKey)
    }
    
    private static func loadRecipeFeedback() -> [RecipeFeedback] {
        return loadCodable([RecipeFeedback].self, forKey: "recipeFeedback") ?? []
    }
    
    /// Add or update feedback for a recipe
    func saveFeedback(_ feedback: RecipeFeedback) {
        // Remove any existing feedback for this recipe
        recipeFeedback.removeAll { $0.recipeId == feedback.recipeId }
        
        // Add new feedback
        recipeFeedback.append(feedback)
        
        // Keep only last 100 feedback entries
        if recipeFeedback.count > 100 {
            recipeFeedback = Array(recipeFeedback.suffix(100))
        }
        
        saveRecipeFeedbackData()
        
        // Log activity
        logActivity(.submittedFeedback(feedback))
        
        // Sync to cloud in background
        syncRecipeFeedbackToCloud(feedback)
    }
    
    /// Get feedback for a specific recipe
    func getFeedback(for recipeId: UUID) -> RecipeFeedback? {
        recipeFeedback.first { $0.recipeId == recipeId }
    }
    
    /// Check if a recipe has feedback
    func hasFeedback(for recipeId: UUID) -> Bool {
        recipeFeedback.contains { $0.recipeId == recipeId }
    }
    
    // MARK: - Cloud Sync
    
    /// Check if cloud sync should be performed (must be called from MainActor context)
    @MainActor
    private func checkShouldSyncToCloud() -> Bool {
        GuestModeService.shared.shouldSyncToCloud()
    }
    
    /// Sync a fridge item to the cloud (background)
    private func syncFridgeItemToCloud(_ item: FridgeItem) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                _ = try await SupabaseDataService.shared.addFridgeItem(item)
            } catch {
                DataManager.logger.error("Failed to sync fridge item to cloud: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync deletion of a fridge item to the cloud (background)
    private func syncFridgeItemDeletionToCloud(_ itemId: UUID) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                try await SupabaseDataService.shared.deleteFridgeItem(itemId)
            } catch {
                DataManager.logger.error("Failed to sync fridge item deletion: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync a pantry item to the cloud (background)
    private func syncPantryItemToCloud(_ item: Ingredient) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                _ = try await SupabaseDataService.shared.addPantryItem(item)
            } catch {
                DataManager.logger.error("Failed to sync pantry item to cloud: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync deletion of a pantry item to the cloud (background)
    private func syncPantryItemDeletionToCloud(_ itemId: UUID) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                try await SupabaseDataService.shared.deletePantryItem(itemId)
            } catch {
                DataManager.logger.error("Failed to sync pantry item deletion: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync user profile to the cloud (background)
    private func syncUserProfileToCloud() {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                let profileUpdate = ProfileUpdateDTO(name: self.userProfile.name)
                try await SupabaseDataService.shared.updateProfile(profileUpdate)
                
                let preferencesUpdate = UserPreferencesUpdateDTO(
                    dietaryPreferences: self.userProfile.dietaryPreferences,
                    allergies: self.userProfile.allergies,
                    dailyCalories: self.userProfile.macroGoals.dailyCalories,
                    proteinPercentage: self.userProfile.macroGoals.proteinPercentage,
                    carbsPercentage: self.userProfile.macroGoals.carbsPercentage,
                    fatsPercentage: self.userProfile.macroGoals.fatsPercentage,
                    hasMacroGoals: self.userProfile.hasMacroGoals
                )
                try await SupabaseDataService.shared.updateUserPreferences(preferencesUpdate)
            } catch {
                DataManager.logger.error("Failed to sync user profile: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync favorite toggle to the cloud (background)
    private func syncFavoriteToCloud(_ recipe: Recipe, isFavorite: Bool) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                if isFavorite {
                    try await SupabaseDataService.shared.saveRecipeAsFavorite(recipe)
                } else {
                    try await SupabaseDataService.shared.removeRecipeFromFavorites(recipe.id)
                }
            } catch {
                DataManager.logger.error("Failed to sync favorite: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync activity to the cloud (background)
    private func syncActivityToCloud(_ activity: ActivityItem) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                try await SupabaseDataService.shared.logActivity(activity)
            } catch {
                DataManager.logger.error("Failed to sync activity: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync daily macros to the cloud (background)
    private func syncDailyMacrosToCloud() {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                try await SupabaseDataService.shared.updateDailyMacros(self.dailyMacros)
            } catch {
                DataManager.logger.error("Failed to sync daily macros: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Sync recipe feedback to the cloud (background)
    private func syncRecipeFeedbackToCloud(_ feedback: RecipeFeedback) {
        Task { @MainActor in
            guard self.checkShouldSyncToCloud() else { return }
            do {
                try await SupabaseDataService.shared.saveRecipeFeedback(feedback)
            } catch {
                DataManager.logger.error("Failed to sync recipe feedback: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Guest Data Migration
    
    /// Key to track if guest data has been migrated for the current user
    private static let guestDataMigratedKey = "guestDataMigratedForUser"
    
    /// Check if this user has already had their guest data migrated
    private func hasAlreadyMigratedGuestData(for userId: String) -> Bool {
        let migratedUsers = UserDefaults.standard.stringArray(forKey: DataManager.guestDataMigratedKey) ?? []
        return migratedUsers.contains(userId)
    }
    
    /// Mark that guest data has been migrated for this user
    private func markGuestDataAsMigrated(for userId: String) {
        var migratedUsers = UserDefaults.standard.stringArray(forKey: DataManager.guestDataMigratedKey) ?? []
        if !migratedUsers.contains(userId) {
            migratedUsers.append(userId)
            UserDefaults.standard.set(migratedUsers, forKey: DataManager.guestDataMigratedKey)
        }
    }
    
    /// Check if there's meaningful local data to migrate
    private var hasLocalDataToMigrate: Bool {
        !fridgeItems.isEmpty ||
        !pantryItems.filter { item in
            !Ingredient.pantryItems.contains(where: { $0.name == item.name })
        }.isEmpty ||
        !favoriteRecipes.isEmpty ||
        !chatSessions.isEmpty ||
        dailyMacros.caloriesConsumed > 0 ||
        !activityLog.isEmpty
    }
    
    /// Migrate local guest data to the cloud on first authentication.
    /// This should be called BEFORE loadFromCloud() when a guest user creates an account.
    ///
    /// The flow:
    /// 1. Check if user has local data worth migrating
    /// 2. Push local data UP to the cloud
    /// 3. Mark migration as complete for this user
    ///
    /// After calling this, call loadFromCloud() to merge any existing cloud data.
    ///
    /// - Returns: `true` if migration succeeded or was skipped (no data to migrate),
    ///            `false` if migration failed and should be retried
    @MainActor
    @discardableResult
    func migrateGuestDataOnFirstAuth() async -> Bool {
        // Safety check: only sync if authenticated and not in guest mode
        // If this fails, something is wrong - don't clear the flag so we can retry
        guard checkShouldSyncToCloud() else {
            DataManager.logger.warning("Migration called but sync conditions not met (isGuestMode=\(GuestModeService.shared.isGuestMode), isAuthenticated=\(AuthService.shared.isAuthenticated))")
            return false
        }
        
        // Prevent concurrent migrations (race condition between OnboardingAuthView and DashboardView)
        // Return false so the caller does NOT clear wasInGuestMode flag
        // The other caller (the one actually syncing) will clear the flag if it succeeds
        guard !isSyncing else {
            DataManager.logger.info("Migration already in progress, skipping duplicate call")
            return false
        }
        
        // Get current user ID
        guard let userId = AuthService.shared.currentUser?.id.uuidString else {
            DataManager.logger.warning("Cannot migrate: No authenticated user")
            return false
        }
        
        // Skip if already migrated for this user
        guard !hasAlreadyMigratedGuestData(for: userId) else {
            DataManager.logger.info("Guest data already migrated for user")
            return true
        }
        
        // Skip if no meaningful local data
        guard hasLocalDataToMigrate else {
            DataManager.logger.info("No local data to migrate")
            markGuestDataAsMigrated(for: userId)
            return true
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Push all local data to cloud (this preserves guest data)
            try await SupabaseDataService.shared.syncAllDataToCloud(
                profile: userProfile,
                fridgeItems: fridgeItems,
                pantryItems: pantryItems,
                favoriteRecipes: favoriteRecipes,
                chatSessions: chatSessions,
                dailyMacros: dailyMacros,
                activityLog: activityLog
            )
            
            // Mark as migrated so we don't duplicate on next login
            markGuestDataAsMigrated(for: userId)
            
            DataManager.logger.info("Successfully migrated guest data")
            isSyncing = false
            return true
            
        } catch {
            DataManager.logger.error("Failed to migrate guest data: \(error.localizedDescription, privacy: .public)")
            syncError = "Failed to migrate your data: \(error.localizedDescription)"
            isSyncing = false
            return false
        }
    }
    
    // MARK: - Load from Cloud
    
    /// Load all data from cloud and merge with local
    /// Call this after successful authentication.
    /// If the user was previously a guest, call migrateGuestDataOnFirstAuth() first.
    @MainActor
    func loadFromCloud() async {
        guard checkShouldSyncToCloud() else { return }
        
        isLoadingFromCloud = true
        syncError = nil
        
        do {
            let cloudData = try await SupabaseDataService.shared.loadAllDataFromCloud()
            
            // Update profile if cloud has data
            if let profile = cloudData.profile, let preferences = cloudData.preferences {
                userProfile = UserProfile(
                    name: profile.name ?? userProfile.name,
                    email: profile.email ?? userProfile.email,
                    dietaryPreferences: preferences.dietaryPreferences,
                    allergies: preferences.allergies,
                    macroGoals: UserProfile.MacroGoals(
                        dailyCalories: preferences.dailyCalories,
                        proteinPercentage: preferences.proteinPercentage,
                        carbsPercentage: preferences.carbsPercentage,
                        fatsPercentage: preferences.fatsPercentage
                    ),
                    hasMacroGoals: preferences.hasMacroGoals
                )
                saveUserProfile()
            }
            
            // Merge fridge items (cloud wins if there are items)
            if !cloudData.fridgeItems.isEmpty {
                fridgeItems = cloudData.fridgeItems.map { $0.toFridgeItem() }
                saveFridgeItems()
            }
            
            // Merge pantry items (cloud wins if there are items)
            if !cloudData.pantryItems.isEmpty {
                pantryItems = cloudData.pantryItems.map { $0.toIngredient() }
                savePantryItems()
            }
            
            // Merge favorites (cloud wins if there are items)
            if !cloudData.favoriteRecipes.isEmpty {
                favoriteRecipes = cloudData.favoriteRecipes.map { $0.toRecipe() }
                saveFavoriteRecipes()
            }
            
            // Merge chat sessions (cloud wins if there are items)
            if !cloudData.chatSessions.isEmpty {
                chatSessions = cloudData.chatSessions.map { $0.toChatSession() }
                saveChatSessions()
            }
            
            // Merge today's macro log (cloud wins if exists)
            if let cloudMacros = cloudData.macroLog {
                dailyMacros = cloudMacros.toDailyMacroLog()
                saveDailyMacros()
            }
            
            // Merge activity feed (cloud wins if there are items)
            if !cloudData.activityFeed.isEmpty {
                activityLog = cloudData.activityFeed.compactMap { $0.toActivityItem() }
                saveActivityLog()
            }
            
            lastSyncDate = Date()
            isLoadingFromCloud = false
            
        } catch {
            DataManager.logger.error("Failed to load from cloud: \(error.localizedDescription, privacy: .public)")
            syncError = error.localizedDescription
            isLoadingFromCloud = false
        }
    }
    
    // MARK: - Sync All to Cloud
    
    /// Push all local data to cloud
    /// Call this after first login to upload existing local data
    @MainActor
    func syncAllToCloud() async {
        guard checkShouldSyncToCloud() else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            try await SupabaseDataService.shared.syncAllDataToCloud(
                profile: userProfile,
                fridgeItems: fridgeItems,
                pantryItems: pantryItems,
                favoriteRecipes: favoriteRecipes,
                chatSessions: chatSessions,
                dailyMacros: dailyMacros,
                activityLog: activityLog
            )
            
            lastSyncDate = Date()
            isSyncing = false
            
        } catch {
            DataManager.logger.error("Failed to sync all to cloud: \(error.localizedDescription, privacy: .public)")
            syncError = error.localizedDescription
            isSyncing = false
        }
    }
    
    /// Clear sync error
    func clearSyncError() {
        syncError = nil
    }
    
    /// Clear all locally stored user data (used on sign-out/account deletion)
    func clearLocalUserData() {
        let defaults = UserDefaults.standard
        let keysToClear = [
            userProfileKey,
            pantryItemsKey,
            recipeHistoryKey,
            dailyMacrosKey,
            cookedRecipesKey,
            recipeRatingsKey,
            fridgeItemsKey,
            lastFridgeScanDateKey,
            activityLogKey,
            lastPantryUpdateDateKey,
            favoriteRecipesKey,
            generalChatHistoryKey,
            recipeChatHistoriesKey,
            macroHistoryKey,
            recipeFeedbackKey,
            chatSessionsKey
        ]
        
        for key in keysToClear {
            defaults.removeObject(forKey: key)
        }

        do {
            try KeychainService.shared.delete(DataManager.userProfileKeychainKey)
        } catch {
            DataManager.logger.error("Failed to delete user profile from Keychain: \(error.localizedDescription, privacy: .public)")
        }
        
        // Reset all in-memory data to defaults
        // Note: pantryItems is empty - users set up pantry during onboarding
        userProfile = UserProfile.dummy
        pantryItems = []
        recipeHistory = []
        dailyMacros = DailyMacroLog()
        cookedRecipeIDs = []
        recipeRatings = [:]
        fridgeItems = []
        lastFridgeScanDate = nil
        activityLog = []
        lastPantryUpdateDate = nil
        favoriteRecipes = []
        generalChatHistory = []
        recipeChatHistories = [:]
        macroHistory = []
        recipeFeedback = []
        chatSessions = []
        
        isSyncing = false
        syncError = nil
        lastSyncDate = nil
        isLoadingFromCloud = false
    }
}

// MARK: - Recipe Feedback Model
struct RecipeFeedback: Codable, Identifiable {
    var id = UUID()
    var recipeId: UUID
    var recipeName: String
    var rating: Int  // 1-5 stars
    var enjoyed: Bool
    var comments: String
    var timestamp: Date = Date()
}

// MARK: - Daily Macro Log Model
struct DailyMacroLog: Codable, Identifiable {
    var id: String { dateString }
    var date: Date = Date()
    var caloriesConsumed: Int = 0
    var proteinConsumed: Double = 0
    var carbsConsumed: Double = 0
    var fatsConsumed: Double = 0
    
    /// Date string for identification (YYYY-MM-DD format)
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Display date string (e.g., "Jan 14")
    var displayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Check if this log is from today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
