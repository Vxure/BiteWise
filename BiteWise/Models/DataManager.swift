import Foundation
import SwiftUI

// MARK: - Data Manager for Local Persistence
class DataManager: ObservableObject {
    static let shared = DataManager()
    
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
    
    private let userProfileKey = "userProfile"
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
        // Load saved data or use defaults
        self.userProfile = DataManager.loadUserProfile() ?? UserProfile.dummy
        self.pantryItems = DataManager.loadPantryItems() ?? Ingredient.pantryItems
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
    
    // MARK: - User Profile
    func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: userProfileKey)
        }
    }
    
    private static func loadUserProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    // MARK: - Pantry Items
    func savePantryItems() {
        if let encoded = try? JSONEncoder().encode(pantryItems) {
            UserDefaults.standard.set(encoded, forKey: pantryItemsKey)
        }
        // Update the last pantry update date
        lastPantryUpdateDate = Date()
        saveLastPantryUpdateDate()
    }
    
    private static func loadPantryItems() -> [Ingredient]? {
        guard let data = UserDefaults.standard.data(forKey: "pantryItems"),
              let items = try? JSONDecoder().decode([Ingredient].self, from: data) else {
            return nil
        }
        return items
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
    }
    
    func removePantryItem(_ item: Ingredient) {
        pantryItems.removeAll { $0.id == item.id }
        savePantryItems()
    }
    
    // MARK: - Recipe History
    func saveRecipeHistory() {
        if let encoded = try? JSONEncoder().encode(recipeHistory) {
            UserDefaults.standard.set(encoded, forKey: recipeHistoryKey)
        }
    }
    
    private static func loadRecipeHistory() -> [Recipe]? {
        guard let data = UserDefaults.standard.data(forKey: "recipeHistory"),
              let history = try? JSONDecoder().decode([Recipe].self, from: data) else {
            return nil
        }
        return history
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
        if let encoded = try? JSONEncoder().encode(dailyMacros) {
            UserDefaults.standard.set(encoded, forKey: dailyMacrosKey)
        }
    }
    
    private static func loadDailyMacros() -> DailyMacroLog? {
        guard let data = UserDefaults.standard.data(forKey: "dailyMacros"),
              let macros = try? JSONDecoder().decode(DailyMacroLog.self, from: data) else {
            return nil
        }
        return macros
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
        if let encoded = try? JSONEncoder().encode(macroHistory) {
            UserDefaults.standard.set(encoded, forKey: macroHistoryKey)
        }
    }
    
    private static func loadMacroHistory() -> [DailyMacroLog] {
        guard let data = UserDefaults.standard.data(forKey: "macroHistory"),
              let history = try? JSONDecoder().decode([DailyMacroLog].self, from: data) else {
            return []
        }
        return history
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
        if let encoded = try? JSONEncoder().encode(fridgeItems) {
            UserDefaults.standard.set(encoded, forKey: fridgeItemsKey)
        }
    }
    
    private static func loadFridgeItems() -> [FridgeItem] {
        guard let data = UserDefaults.standard.data(forKey: "fridgeItems"),
              let items = try? JSONDecoder().decode([FridgeItem].self, from: data) else {
            return []
        }
        return items
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
    }
    
    /// Remove fridge item by ID
    func removeFridgeItem(withId id: UUID) {
        fridgeItems.removeAll { $0.id == id }
        saveFridgeItems()
    }
    
    /// Clear all fridge items
    func clearAllFridgeItems() {
        fridgeItems.removeAll()
        lastFridgeScanDate = nil
        saveFridgeItems()
        UserDefaults.standard.removeObject(forKey: lastFridgeScanDateKey)
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
        if let encoded = try? JSONEncoder().encode(activityLog) {
            UserDefaults.standard.set(encoded, forKey: activityLogKey)
        }
    }
    
    private static func loadActivityLog() -> [ActivityItem] {
        guard let data = UserDefaults.standard.data(forKey: "activityLog"),
              let activities = try? JSONDecoder().decode([ActivityItem].self, from: data) else {
            return []
        }
        return activities
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
        if let encoded = try? JSONEncoder().encode(favoriteRecipes) {
            UserDefaults.standard.set(encoded, forKey: favoriteRecipesKey)
        }
    }
    
    private static func loadFavoriteRecipes() -> [Recipe] {
        guard let data = UserDefaults.standard.data(forKey: "favoriteRecipes"),
              let recipes = try? JSONDecoder().decode([Recipe].self, from: data) else {
            return []
        }
        return recipes
    }
    
    /// Check if a recipe is favorited
    func isFavorite(_ recipe: Recipe) -> Bool {
        favoriteRecipes.contains { $0.id == recipe.id }
    }
    
    /// Toggle favorite status for a recipe
    func toggleFavorite(_ recipe: Recipe) {
        if let index = favoriteRecipes.firstIndex(where: { $0.id == recipe.id }) {
            favoriteRecipes.remove(at: index)
        } else {
            favoriteRecipes.append(recipe)
            logActivity(.favoritedRecipe(recipe))
        }
        saveFavoriteRecipes()
    }
    
    /// Add a recipe to favorites
    func addFavorite(_ recipe: Recipe) {
        if !isFavorite(recipe) {
            favoriteRecipes.append(recipe)
            logActivity(.favoritedRecipe(recipe))
            saveFavoriteRecipes()
        }
    }
    
    /// Remove a recipe from favorites
    func removeFavorite(_ recipe: Recipe) {
        favoriteRecipes.removeAll { $0.id == recipe.id }
        saveFavoriteRecipes()
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
        if let encoded = try? JSONEncoder().encode(generalChatHistory) {
            UserDefaults.standard.set(encoded, forKey: generalChatHistoryKey)
        }
    }
    
    private static func loadGeneralChatHistory() -> [ChatMessage] {
        guard let data = UserDefaults.standard.data(forKey: "generalChatHistory"),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return messages
    }
    
    func saveRecipeChatHistories() {
        // Convert UUID keys to strings for JSON encoding
        let stringKeyed = Dictionary(uniqueKeysWithValues: recipeChatHistories.map { ($0.key.uuidString, $0.value) })
        if let encoded = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(encoded, forKey: recipeChatHistoriesKey)
        }
    }
    
    private static func loadRecipeChatHistories() -> [UUID: [ChatMessage]] {
        guard let data = UserDefaults.standard.data(forKey: "recipeChatHistories"),
              let stringKeyed = try? JSONDecoder().decode([String: [ChatMessage]].self, from: data) else {
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
        if let encoded = try? JSONEncoder().encode(chatSessions) {
            UserDefaults.standard.set(encoded, forKey: chatSessionsKey)
        }
    }
    
    private static func loadChatSessions() -> [ChatSession] {
        guard let data = UserDefaults.standard.data(forKey: "chatSessions"),
              let sessions = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return []
        }
        return sessions
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
        if let encoded = try? JSONEncoder().encode(recipeFeedback) {
            UserDefaults.standard.set(encoded, forKey: recipeFeedbackKey)
        }
    }
    
    private static func loadRecipeFeedback() -> [RecipeFeedback] {
        guard let data = UserDefaults.standard.data(forKey: "recipeFeedback"),
              let feedback = try? JSONDecoder().decode([RecipeFeedback].self, from: data) else {
            return []
        }
        return feedback
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
    }
    
    /// Get feedback for a specific recipe
    func getFeedback(for recipeId: UUID) -> RecipeFeedback? {
        recipeFeedback.first { $0.recipeId == recipeId }
    }
    
    /// Check if a recipe has feedback
    func hasFeedback(for recipeId: UUID) -> Bool {
        recipeFeedback.contains { $0.recipeId == recipeId }
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