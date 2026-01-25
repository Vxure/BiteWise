import Foundation
import SwiftUI

// MARK: - App Theme
/// Theme options for the app appearance
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    /// Returns the preferred ColorScheme for SwiftUI, nil means follow system
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// App-wide settings manager with demo mode control
/// Handles the toggle between using real Gemini API calls and dummy data
class AppSettings: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppSettings()
    
    // MARK: - UserDefaults Keys
    private let demoModeKey = "isDemoMode"
    private let fridgeAutoExpireEnabledKey = "fridgeAutoExpireEnabled"
    private let fridgeAutoExpireDaysKey = "fridgeAutoExpireDays"
    
    // Chat settings keys
    private let chatAutoExpireEnabledKey = "chatAutoExpireEnabled"
    private let generalChatExpireDaysKey = "generalChatExpireDays"
    private let recipeChatExpireDaysKey = "recipeChatExpireDays"
    private let keepRecipeChatsLongerKey = "keepRecipeChatsLonger"
    
    // Scan behavior key
    private let defaultScanMethodKey = "defaultScanMethod"
    
    // Appearance key
    private let appThemeKey = "appTheme"
    
    // MARK: - Published Properties
    
    /// When true, ALL API calls are bypassed and dummy data is used instead
    /// This is checked BEFORE any network request is made to avoid wasting API quota
    @Published var isDemoMode: Bool {
        didSet {
            UserDefaults.standard.set(isDemoMode, forKey: demoModeKey)
        }
    }
    
    /// When true, fridge items older than `fridgeAutoExpireDays` are automatically removed
    @Published var fridgeAutoExpireEnabled: Bool {
        didSet {
            UserDefaults.standard.set(fridgeAutoExpireEnabled, forKey: fridgeAutoExpireEnabledKey)
        }
    }
    
    /// Number of days after which fridge items expire (when auto-expire is enabled)
    @Published var fridgeAutoExpireDays: Int {
        didSet {
            UserDefaults.standard.set(fridgeAutoExpireDays, forKey: fridgeAutoExpireDaysKey)
        }
    }
    
    /// When true, chat messages older than the configured days are automatically removed
    @Published var chatAutoExpireEnabled: Bool {
        didSet {
            UserDefaults.standard.set(chatAutoExpireEnabled, forKey: chatAutoExpireEnabledKey)
        }
    }
    
    /// Number of days after which general chat messages expire
    @Published var generalChatExpireDays: Int {
        didSet {
            UserDefaults.standard.set(generalChatExpireDays, forKey: generalChatExpireDaysKey)
        }
    }
    
    /// Number of days after which recipe-specific chat messages expire
    @Published var recipeChatExpireDays: Int {
        didSet {
            UserDefaults.standard.set(recipeChatExpireDays, forKey: recipeChatExpireDaysKey)
        }
    }
    
    /// When true, recipe chats use their own expiration period; otherwise use general chat period
    @Published var keepRecipeChatsLonger: Bool {
        didSet {
            UserDefaults.standard.set(keepRecipeChatsLonger, forKey: keepRecipeChatsLongerKey)
            // When enabled, initialize recipe chat days to match general chat days
            if keepRecipeChatsLonger && recipeChatExpireDays < generalChatExpireDays {
                recipeChatExpireDays = generalChatExpireDays
            }
        }
    }
    
    /// Default scan method for handling inventory updates
    /// Options: askEveryTime (default), smartMerge, add, replace
    @Published var defaultScanMethod: ScanMergeMode {
        didSet {
            UserDefaults.standard.set(defaultScanMethod.rawValue, forKey: defaultScanMethodKey)
        }
    }
    
    /// App appearance theme: system, light, or dark
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: appThemeKey)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved preference or default to demo mode ON (safe default)
        // This prevents accidental API calls when:
        // 1. User hasn't configured an API key yet
        // 2. User is just exploring the app
        let savedDemoMode = UserDefaults.standard.object(forKey: demoModeKey) as? Bool
        
        if let saved = savedDemoMode {
            self.isDemoMode = saved
        } else {
            // First launch: enable demo mode by default (safe default)
            self.isDemoMode = true
            UserDefaults.standard.set(true, forKey: demoModeKey)
        }
        
        // Load fridge auto-expire settings
        self.fridgeAutoExpireEnabled = UserDefaults.standard.bool(forKey: fridgeAutoExpireEnabledKey)
        
        let savedExpireDays = UserDefaults.standard.integer(forKey: fridgeAutoExpireDaysKey)
        self.fridgeAutoExpireDays = savedExpireDays > 0 ? savedExpireDays : 7 // Default to 7 days
        
        // Load chat auto-expire settings
        // Default to true for auto-expire
        if UserDefaults.standard.object(forKey: chatAutoExpireEnabledKey) == nil {
            self.chatAutoExpireEnabled = true
            UserDefaults.standard.set(true, forKey: chatAutoExpireEnabledKey)
        } else {
            self.chatAutoExpireEnabled = UserDefaults.standard.bool(forKey: chatAutoExpireEnabledKey)
        }
        
        let savedGeneralChatDays = UserDefaults.standard.integer(forKey: generalChatExpireDaysKey)
        self.generalChatExpireDays = savedGeneralChatDays > 0 ? savedGeneralChatDays : 15 // Default to 15 days
        
        let savedRecipeChatDays = UserDefaults.standard.integer(forKey: recipeChatExpireDaysKey)
        // Default recipe chat to match general chat setting
        let defaultRecipeDays = savedGeneralChatDays > 0 ? savedGeneralChatDays : 15
        self.recipeChatExpireDays = savedRecipeChatDays > 0 ? savedRecipeChatDays : defaultRecipeDays
        
        self.keepRecipeChatsLonger = UserDefaults.standard.bool(forKey: keepRecipeChatsLongerKey)
        
        // Load default scan method
        if let savedScanMethod = UserDefaults.standard.string(forKey: defaultScanMethodKey),
           let scanMode = ScanMergeMode(rawValue: savedScanMethod) {
            self.defaultScanMethod = scanMode
        } else {
            self.defaultScanMethod = .askEveryTime // Default to asking every time
        }
        
        // Load app theme
        if let savedTheme = UserDefaults.standard.string(forKey: appThemeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.appTheme = theme
        } else {
            self.appTheme = .system // Default to system theme
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns true ONLY if we should make real API calls
    /// This is the primary check used by all services before making network requests
    /// 
    /// Conditions for real API usage:
    /// 1. Demo mode must be explicitly OFF
    /// 2. A valid API key must be configured
    ///
    /// If either condition fails, services should use dummy data
    var shouldUseRealAPI: Bool {
        !isDemoMode && APIConfiguration.hasValidAPIKey
    }
    
    /// Human-readable status message for display in Settings UI
    var apiStatusMessage: String {
        if isDemoMode {
            return "Using sample data"
        } else if !APIConfiguration.hasValidAPIKey {
            return "API key not configured"
        } else {
            return "Using Gemini API"
        }
    }
    
    /// Detailed status for debugging
    var detailedStatus: String {
        """
        Demo Mode: \(isDemoMode ? "ON" : "OFF")
        API Key Valid: \(APIConfiguration.hasValidAPIKey ? "YES" : "NO")
        Will Use Real API: \(shouldUseRealAPI ? "YES" : "NO")
        Model: \(APIConfiguration.geminiModel)
        """
    }
    
    // MARK: - Helper Methods
    
    /// Toggle demo mode with haptic feedback
    func toggleDemoMode() {
        isDemoMode.toggle()
    }
    
    /// Reset to safe defaults (demo mode ON)
    func resetToDefaults() {
        isDemoMode = true
    }
}

