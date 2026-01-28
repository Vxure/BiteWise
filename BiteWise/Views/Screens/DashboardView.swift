import SwiftUI 

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DashboardView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var isVisible = false
    @AppStorage("hasSeenWelcomeHint") private var hasSeenWelcomeHint: Bool = false
    @State private var hasLoadedFromCloud = false
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Empty state CTA action
    @State private var showingLogBreakfastSheet: Bool = false
    
    // Header configuration
    private let headerHeight: CGFloat = 45
    
    // Time-based greeting
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    // Greeting emoji
    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "🌅"
        case 12..<17: return "☀️"
        default: return "🌙"
        }
    }
    
    // Next meal suggestion based on time
    private var nextMeal: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<11: return "Breakfast"
        case 11..<15: return "Lunch"
        case 15..<18: return "Snack"
        default: return "Dinner"
        }
    }
    
    // MARK: - Header Animation Calculations
    
    private var scrollProgress: CGFloat {
        min(1, max(0, -scrollOffset / headerHeight))
    }
    
    private var headerOpacity: Double {
        if headerVisible {
            return 1.0
        }
        return Double(1.0 - scrollProgress)
    }
    
    private var headerTranslateY: CGFloat {
        if headerVisible {
            return 0
        }
        return -headerHeight * scrollProgress
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
            .ignoresSafeArea()
            
            // Content ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Invisible anchor for scroll offset tracking
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                    }
                    .frame(height: 0)
                    
                    // Spacer for the floating header
                    Color.clear
                        .frame(height: headerHeight)
                    
                    // MARK: - Greeting Header (simplified)
                    greetingHeaderSection
                        .staggeredAppear(index: 0)
                    
                    // MARK: - First-time User Guidance
                    if !hasSeenWelcomeHint && !dataManager.hasFridgeItems {
                        welcomeGuidanceSection
                            .staggeredAppear(index: 1)
                    }
                    
                    // MARK: - Quick Actions (NEW - primary focus)
                    quickActionsSection
                        .staggeredAppear(index: hasSeenWelcomeHint || dataManager.hasFridgeItems ? 1 : 2)
                    
                    // MARK: - Pantry Overview (NEW)
                    pantryOverviewSection
                        .staggeredAppear(index: 3)
                    
                    // MARK: - Fridge Overview (NEW)
                    fridgeOverviewSection
                        .staggeredAppear(index: 4)
                    
                    // MARK: - Running Low (moved up - actionable)
                    runningLowSection
                        .staggeredAppear(index: 5)
                    
                    // MARK: - Today's Progress (moved down - secondary)
                    macroOverviewSection
                        .staggeredAppear(index: 6)
                    
                    // MARK: - Recently Cooked (moved down)
                    recentlyCookedSection
                        .staggeredAppear(index: 7)
                    
                    // MARK: - Up Next Suggestion (bottom)
                    upNextSection
                        .staggeredAppear(index: 8)
                    
                    // MARK: - Recent Activity (bottom)
                    recentActivitySection
                        .staggeredAppear(index: 9)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 1)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }
            .background(Color.clear)
            
            // MARK: - Floating Header Overlay
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BWGradients.headerFadeGradient(for: colorScheme))
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
        }
        .onAppear {
            isVisible = true
        }
        .task {
            // Load data from cloud if authenticated and haven't loaded yet
            if authService.isAuthenticated && !hasLoadedFromCloud {
                hasLoadedFromCloud = true
                await dataManager.loadFromCloud()
            }
        }
        .overlay(alignment: .top) {
            // Show sync error banner if there's an error
            if let error = dataManager.syncError {
                BWErrorBanner(
                    message: error,
                    onDismiss: { dataManager.clearSyncError() },
                    onRetry: {
                        Task {
                            await dataManager.loadFromCloud()
                        }
                    }
                )
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dataManager.syncError)
    }
    
    // MARK: - Scroll Handling
    
    private func handleScrollChange(newOffset: CGFloat) {
        let delta = newOffset - lastScrollOffset
        
        if delta > 2 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        } else if delta < -2 {
            if headerVisible && newOffset < -10 {
                withAnimation(.easeOut(duration: 0.15)) {
                    headerVisible = false
                }
            }
        }
        
        if newOffset >= -5 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        }
        
        scrollOffset = newOffset
        lastScrollOffset = newOffset
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Dashboard")
                .font(BWTypography.sectionHeader)
            
            // Show sync status if authenticated
            if authService.isAuthenticated {
                BWSyncStatusIndicator()
            }
            
            Spacer()
            
            // Favorites button
            Button(action: {
                BWHaptics.lightImpact()
                navigationState.navigateTo(.favorites)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 44, height: 44)
                        .adaptiveShadow(color: Color.bwAdaptiveAccent(for: colorScheme).opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: dataManager.hasFavorites ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.bwAdaptiveAccent(for: colorScheme))
                }
            }
            .buttonStyle(.bwPressable)
            
            // Profile button
            Button(action: {
                BWHaptics.lightImpact()
                navigationState.navigateTo(.userProfile)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 44, height: 44)
                        .adaptiveShadow(color: Color.bwAdaptivePrimary(for: colorScheme).opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                }
            }
            .buttonStyle(.bwPressable)
        }
    }
    
    // MARK: - Greeting Header
    private var greetingHeaderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(greetingEmoji) Good \(timeOfDay), \(dataManager.userProfile.name.isEmpty ? "there" : dataManager.userProfile.name)!")
                .font(BWTypography.cardTitle)
                .foregroundColor(.primary)
            
            Text("Ready to cook something good?")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }
    
    // MARK: - Welcome Guidance (First-time users)
    private var welcomeGuidanceSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bwPrimary.opacity(0.15), Color.bwSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.bwPrimary)
            }
            
            VStack(spacing: 8) {
                Text("Welcome to BiteWise!")
                    .font(BWTypography.cardTitle)
                    .foregroundColor(.primary)
                
                Text("Start by scanning your fridge to discover personalized recipe ideas based on what you have.")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Scan button
            Button(action: {
                BWHaptics.mediumImpact()
                hasSeenWelcomeHint = true
                navigationState.navigateTo(.photoUpload)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Scan My Fridge")
                        .font(BWTypography.buttonSmall)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.bwPrimary, Color.bwSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.bwPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.bwPressable)
            
            // Dismiss link
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    hasSeenWelcomeHint = true
                }
            }) {
                Text("I'll explore first")
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .adaptiveShadow(color: Color.bwAdaptivePrimary(for: colorScheme).opacity(0.1), radius: 16, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.bwPrimary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to do?")
                .font(BWTypography.cardTitle)
            
            HStack(spacing: 12) {
                // Scan Ingredients
                Button(action: {
                    BWHaptics.mediumImpact()
                    navigationState.navigateTo(.photoUpload)
                }) {
                    quickActionButton(
                        icon: "camera.fill",
                        title: "Scan",
                        subtitle: "Ingredients",
                        color: Color.bwPrimary
                    )
                }
                .buttonStyle(.bwPressable)
                
                // Ask AI
                Button(action: {
                    BWHaptics.mediumImpact()
                    navigationState.navigateTo(.recipeAIAssistant)
                }) {
                    quickActionButton(
                        icon: "sparkles",
                        title: "Ask AI",
                        subtitle: "Get recipes",
                        color: Color.bwAccent
                    )
                }
                .buttonStyle(.bwPressable)
                
                // My Favorites
                Button(action: {
                    BWHaptics.mediumImpact()
                    navigationState.navigateTo(.favorites)
                }) {
                    quickActionButton(
                        icon: "star.fill",
                        title: "Favorites",
                        subtitle: "\(dataManager.favoriteRecipes.count) saved",
                        color: Color.bwProtein
                    )
                }
                .buttonStyle(.bwPressable)
            }
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }
    
    private func quickActionButton(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .adaptiveShadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemBackground))
        )
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Favorites Preview
    private var favoritesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Favorites")
                    .font(BWTypography.cardTitle)
                
                Spacer()
                
                if dataManager.hasFavorites {
                    Button(action: {
                        BWHaptics.lightImpact()
                        navigationState.navigateTo(.favorites)
                    }) {
                        Text("See All")
                            .font(BWTypography.buttonSmall)
                            .foregroundColor(Color.bwAccent)
                    }
                }
            }
            
            if dataManager.hasFavorites {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(dataManager.favoriteRecipes.prefix(3)) { recipe in
                            Button(action: {
                                BWHaptics.lightImpact()
                                navigationState.navigateTo(.recipeDetail(recipe))
                            }) {
                                favoritePreviewCard(recipe: recipe)
                            }
                            .buttonStyle(.bwPressable)
                        }
                    }
                    .padding(.bottom, 4)
                    .padding(.horizontal, 2)
                }
            } else {
                // Empty state
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.bwAccent.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "star")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwAccent.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No favorites yet")
                            .font(BWTypography.bodyPrimary)
                            .fontWeight(.medium)
                        
                        Text("Save recipes you love by tapping the star icon")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .adaptiveShadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            }
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }
    
    private func favoritePreviewCard(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.bwAccent.opacity(0.25), Color.bwAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(Color.bwAccent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title)
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(recipe.prepTime + recipe.cookTime) min")
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Pantry Overview
    private var pantryOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Pantry")
                    .font(BWTypography.cardTitle)
                
                Spacer()
                
                if !dataManager.pantryItems.isEmpty {
                    Button(action: {
                        BWHaptics.lightImpact()
                        navigationState.navigateTo(.pantryItems)
                    }) {
                        Text("View All")
                            .font(BWTypography.buttonSmall)
                            .foregroundColor(Color.bwPantryBrown)
                    }
                }
            }
            
            Button(action: {
                BWHaptics.lightImpact()
                navigationState.navigateTo(.pantryItems)
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bwPantryBrown.opacity(0.2), Color.bwPantryBrown.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwPantryBrown)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(dataManager.pantryItems.count) items")
                            .font(BWTypography.bodyPrimary)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let timeAgo = dataManager.lastPantryUpdateTimeAgo {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text("Updated \(timeAgo)")
                                    .font(BWTypography.captionSmall)
                            }
                            .foregroundColor(Color.bwPantryBrown.opacity(0.8))
                        } else {
                            Text("Tap to manage")
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        BWHaptics.lightImpact()
                        navigationState.navigateTo(.photoUpload)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Scan")
                                .font(BWTypography.buttonSmall)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.bwPantryBrown)
                        )
                        .shadow(color: Color.bwPantryBrown.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.bwPressable)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }
    
    // MARK: - Fridge Overview
    private var fridgeOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Fridge")
                    .font(BWTypography.cardTitle)
                
                Spacer()
                
                if dataManager.hasFridgeItems {
                    Button(action: {
                        BWHaptics.lightImpact()
                        navigationState.navigateTo(.fridgeItems)
                    }) {
                        Text("View All")
                            .font(BWTypography.buttonSmall)
                            .foregroundColor(Color.bwFridgeBlue)
                    }
                }
            }
            
            Button(action: {
                BWHaptics.lightImpact()
                navigationState.navigateTo(.fridgeItems)
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bwFridgeBlue.opacity(0.2), Color.bwFridgeBlue.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "snowflake")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwFridgeBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if dataManager.hasFridgeItems {
                            Text("\(dataManager.fridgeItems.count) items")
                                .font(BWTypography.bodyPrimary)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if let timeAgo = dataManager.lastFridgeScanTimeAgo {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                    Text("Scanned \(timeAgo)")
                                        .font(BWTypography.captionSmall)
                                }
                                .foregroundColor(Color.bwFridgeBlue.opacity(0.8))
                            }
                        } else {
                            Text("No items scanned")
                                .font(BWTypography.bodyPrimary)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Scan your fridge to get started")
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Scan button
                    Button(action: {
                        BWHaptics.lightImpact()
                        navigationState.navigateTo(.photoUpload)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: dataManager.hasFridgeItems ? "plus" : "camera.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(dataManager.hasFridgeItems ? "Scan" : "Scan")
                                .font(BWTypography.buttonSmall)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.bwFridgeBlue)
                        )
                        .shadow(color: Color.bwFridgeBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.bwPressable)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }
    
    // MARK: - Macro Overview
    
    // Computed properties for macro display
    private var calorieGoal: Int {
        dataManager.userProfile.macroGoals.dailyCalories
    }
    
    private var caloriesConsumed: Int {
        // Reset daily macros if it's a new day
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(dataManager.dailyMacros.date, inSameDayAs: today) {
            return 0
        }
        return dataManager.dailyMacros.caloriesConsumed
    }
    
    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(1.0, Double(caloriesConsumed) / Double(calorieGoal))
    }
    
    private var proteinGoalGrams: Int {
        let cal = Double(dataManager.userProfile.macroGoals.dailyCalories)
        let percentage = dataManager.userProfile.macroGoals.proteinPercentage
        // Protein has 4 calories per gram
        return Int((cal * percentage / 100) / 4)
    }
    
    private var proteinConsumed: Int {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(dataManager.dailyMacros.date, inSameDayAs: today) {
            return 0
        }
        return Int(dataManager.dailyMacros.proteinConsumed)
    }
    
    private var proteinProgress: Double {
        guard proteinGoalGrams > 0 else { return 0 }
        return min(1.0, Double(proteinConsumed) / Double(proteinGoalGrams))
    }
    
    private var macroOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(BWTypography.cardTitle)
                
                Spacer()
                
                Button(action: {
                    BWHaptics.lightImpact()
                    navigationState.navigateTo(.dailyMacroGoals)
                }) {
                    Text("View All")
                        .font(BWTypography.buttonSmall)
                        .foregroundColor(Color.bwAccent)
                }
            }
            
            HStack(spacing: 10) {
                // Calories card with animated progress
                Button(action: {
                    BWHaptics.lightImpact()
                    if caloriesConsumed == 0 {
                        // Show log action for empty state
                        showingLogBreakfastSheet = true
                    } else {
                        navigationState.navigateTo(.dailyMacroGoals)
                    }
                }) {
                    macroCardViewWithCTA(
                        title: "Calories",
                        value: "\(caloriesConsumed)",
                        goal: "of \(calorieGoal)",
                        progress: calorieProgress,
                        icon: "flame.fill",
                        color: Color.red.opacity(0.8),
                        ctaText: caloriesConsumed == 0 ? "Log Breakfast" : nil,
                        ctaIcon: caloriesConsumed == 0 ? "plus.circle" : nil
                    )
                }
                .buttonStyle(.bwPressable)
                
                // Protein card with animated progress
                Button(action: {
                    BWHaptics.lightImpact()
                    if proteinConsumed == 0 {
                        // Navigate to scan for empty state
                        navigationState.navigateTo(.photoUpload)
                    } else {
                        navigationState.navigateTo(.dailyMacroGoals)
                    }
                }) {
                    macroCardViewWithCTA(
                        title: "Protein",
                        value: "\(proteinConsumed)g",
                        goal: "of \(proteinGoalGrams)g",
                        progress: proteinProgress,
                        icon: "leaf.fill",
                        color: Color.green.opacity(0.8),
                        ctaText: proteinConsumed == 0 ? "Scan Lunch" : nil,
                        ctaIcon: proteinConsumed == 0 ? "camera.fill" : nil
                    )
                }
                .buttonStyle(.bwPressable)
            }
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
        .sheet(isPresented: $showingLogBreakfastSheet) {
            LogBreakfastSheet(isPresented: $showingLogBreakfastSheet)
                .environmentObject(navigationState)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func macroCardView(title: String, value: String, goal: String, progress: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            // Animated circular progress ring with icon
            ZStack {
                CircularProgressRing(
                    progress: progress,
                    lineWidth: 6,
                    backgroundColor: Color.white.opacity(0.25),
                    foregroundColor: .white,
                    animateOnAppear: true
                )
                .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(value)
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(goal)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    /// Macro card view with optional CTA for empty states
    private func macroCardViewWithCTA(
        title: String,
        value: String,
        goal: String,
        progress: Double,
        icon: String,
        color: Color,
        ctaText: String? = nil,
        ctaIcon: String? = nil
    ) -> some View {
        VStack(spacing: 10) {
            // Animated circular progress ring with icon
            ZStack {
                CircularProgressRing(
                    progress: progress,
                    lineWidth: 6,
                    backgroundColor: Color.white.opacity(0.25),
                    foregroundColor: .white,
                    animateOnAppear: true
                )
                .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(value)
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(goal)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // CTA for empty state
            if let ctaText = ctaText {
                HStack(spacing: 4) {
                    if let ctaIcon = ctaIcon {
                        Image(systemName: ctaIcon)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    Text(ctaText)
                        .font(BWTypography.captionSmall)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    // MARK: - Recently Cooked
    
    // Get cooked recipes from history
    private var cookedRecipes: [Recipe] {
        dataManager.recipeHistory.filter { dataManager.isCooked($0) }
    }
    
    // Assign colors to recipes based on their position
    private func colorForRecipe(at index: Int) -> Color {
        let colors: [Color] = [Color.bwCarbs, Color.bwPrimary, Color.bwProtein, Color.bwAccent]
        return colors[index % colors.count]
    }
    
    // Assign icons to recipes based on their position
    private func iconForRecipe(at index: Int) -> String {
        let icons = ["fork.knife", "flame", "leaf", "star.fill"]
        return icons[index % icons.count]
    }
    
    private var recentlyCookedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Cooked")
                .font(BWTypography.cardTitle)
            
            if cookedRecipes.isEmpty {
                // Empty state
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.bwCarbs.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "fork.knife")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwCarbs.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No cooked recipes yet")
                            .font(BWTypography.bodyPrimary)
                            .fontWeight(.medium)
                        
                        Text("Mark recipes as cooked to track your cooking!")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .adaptiveShadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(cookedRecipes.prefix(5).enumerated()), id: \.element.id) { index, recipe in
                            Button(action: {
                                BWHaptics.lightImpact()
                                navigationState.navigateTo(.recipeDetail(recipe))
                            }) {
                                recentlyRecipeCard(
                                    title: recipe.title,
                                    date: "Recently",
                                    color: colorForRecipe(at: index),
                                    systemImage: iconForRecipe(at: index)
                                )
                            }
                            .buttonStyle(.bwPressable)
                        }
                    }
                    .padding(.bottom, 4)
                    .padding(.horizontal, 2)
                }
            }
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }
    
    private func recentlyRecipeCard(title: String, date: String, color: Color, systemImage: String, imageName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                
                if let imageName = imageName, let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(date)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Up Next Suggestion
    // Note: Hidden for future use. Uncomment to enable.
    /*
    // Get a suggested recipe: first from favorites, then from recipe history
    private var suggestedRecipe: Recipe? {
        // First try favorites
        if let favorite = dataManager.favoriteRecipes.first {
            return favorite
        }
        // Then try recipe history (first uncooked one)
        if let fromHistory = dataManager.recipeHistory.first(where: { !dataManager.isCooked($0) }) {
            return fromHistory
        }
        // Finally, any recent recipe
        return dataManager.recipeHistory.first
    }
    */
    
    @ViewBuilder
    private var upNextSection: some View {
        // Hidden for future use - uncomment above code to enable
        EmptyView()
    }
    
    // MARK: - Recent Activity
    @ViewBuilder
    private var recentActivitySection: some View {
        if dataManager.hasActivities {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(BWTypography.cardTitle)
                
                VStack(spacing: 0) {
                    let activities = dataManager.recentActivities(limit: 5)
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        activityItemView(activity: activity)
                        
                        if index < activities.count - 1 {
                            Divider()
                                .padding(.leading, 34)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .adaptiveShadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            }
            .bwCardStyle(padding: 14, cornerRadius: 16)
        }
        // If no activities, don't show the section
    }
    
    private func activityItemView(activity: ActivityItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: 16))
                .foregroundColor(activity.color)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(BWTypography.caption)
                    .foregroundColor(.primary)
                
                Text(activity.timeAgoString)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Running Low
    // Note: This section requires ingredient usage tracking to show real data.
    // Hidden until usage tracking is implemented.
    @ViewBuilder
    private var runningLowSection: some View {
        // Only show if we have usage data to analyze
        // Currently hidden as there's no usage tracking system
        EmptyView()
    }
}

// MARK: - Log Breakfast Sheet (Instant Recipes)
/// Sheet showing instant recipe suggestions based on available fridge + pantry items
struct LogBreakfastSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var navigationState: AppNavigationState
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedRecipe: Recipe?
    
    // Generate instant recipe suggestions based on available ingredients
    private var instantRecipes: [Recipe] {
        // Get available ingredient names
        let fridgeNames = dataManager.fridgeItems.map { $0.name.lowercased() }
        let pantryNames = dataManager.pantryItems.map { $0.name.lowercased() }
        let availableIngredients = Set(fridgeNames + pantryNames)
        
        // Filter dummy recipes that can be made with available ingredients
        // Return recipes where at least 60% of main ingredients are available
        let suggestedRecipes = Recipe.dummyData.filter { recipe in
            let recipeIngredients = recipe.ingredients.compactMap { ing -> String? in
                // Parse the ingredient name from the full string
                let words = ing.lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty && $0.count > 2 }
                return words.first
            }
            
            let matchCount = recipeIngredients.filter { ingredient in
                availableIngredients.contains { available in
                    available.contains(ingredient) || ingredient.contains(available)
                }
            }.count
            
            // Need at least 2 matching ingredients or 50% match
            let matchRatio = recipeIngredients.isEmpty ? 0 : Double(matchCount) / Double(recipeIngredients.count)
            return matchCount >= 2 || matchRatio >= 0.5
        }
        
        // If no matching recipes, return first 3 dummy recipes
        return suggestedRecipes.isEmpty ? Array(Recipe.dummyData.prefix(3)) : Array(suggestedRecipes.prefix(4))
    }
    
    // Determine recipe color based on index
    private func colorForRecipe(at index: Int) -> Color {
        let colors: [Color] = [Color.bwPrimary, Color.bwAccent, Color.bwProtein, Color.bwCarbs]
        return colors[index % colors.count]
    }
    
    // Determine recipe icon based on recipe title
    private func iconForRecipe(_ recipe: Recipe) -> String {
        let title = recipe.title.lowercased()
        if title.contains("salad") || title.contains("vegetable") {
            return "leaf.fill"
        } else if title.contains("chicken") || title.contains("stir fry") {
            return "flame.fill"
        } else if title.contains("pasta") || title.contains("risotto") {
            return "fork.knife"
        } else if title.contains("omelet") || title.contains("egg") || title.contains("breakfast") {
            return "sun.max.fill"
        } else if title.contains("yogurt") || title.contains("parfait") {
            return "cup.and.saucer.fill"
        }
        return "fork.knife"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bwPrimary, Color.bwSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Instant Recipes")
                        .font(BWTypography.sectionHeader)
                    
                    Text("Quick recipes based on your fridge & pantry")
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                // Instant recipe suggestions
                VStack(spacing: 12) {
                    ForEach(Array(instantRecipes.enumerated()), id: \.element.id) { index, recipe in
                        Button(action: {
                            BWHaptics.lightImpact()
                            selectedRecipe = recipe
                        }) {
                            HStack(spacing: 14) {
                                // Recipe icon
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [colorForRecipe(at: index).opacity(0.2), colorForRecipe(at: index).opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: iconForRecipe(recipe))
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(colorForRecipe(at: index))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title)
                                        .font(BWTypography.bodyPrimary)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 12) {
                                        // Time
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 10))
                                            Text("\(recipe.prepTime + recipe.cookTime) min")
                                                .font(BWTypography.captionSmall)
                                        }
                                        .foregroundColor(.secondary)
                                        
                                        // Calories
                                        HStack(spacing: 4) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 10))
                                            Text("\(recipe.macros.calories) cal")
                                                .font(BWTypography.captionSmall)
                                        }
                                        .foregroundColor(Color.red.opacity(0.8))
                                        
                                        // Protein
                                        HStack(spacing: 4) {
                                            Text("P:")
                                                .font(.system(size: 10, weight: .semibold))
                                            Text("\(Int(recipe.macros.protein))g")
                                                .font(BWTypography.captionSmall)
                                        }
                                        .foregroundColor(Color.green.opacity(0.8))
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.bwPressable)
                    }
                }
                
                // Ingredient summary
                if !dataManager.fridgeItems.isEmpty || !dataManager.pantryItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Ingredients")
                            .font(BWTypography.captionSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(availableIngredientsText)
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bwPrimary.opacity(0.05))
                    )
                }
                
                // Cancel button
                Button(action: {
                    BWHaptics.lightImpact()
                    isPresented = false
                }) {
                    Text("Close")
                        .font(BWTypography.buttonSmall)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(item: $selectedRecipe) { recipeToShow in
            NavigationStack {
                RecipeDetailScreen(recipe: recipeToShow, onFeedback: {})
            }
        }
    }
    
    private var availableIngredientsText: String {
        let fridgeNames = dataManager.fridgeItems.prefix(3).map { $0.name }
        let pantryNames = dataManager.pantryItems.prefix(3).map { $0.name }
        let combined = (fridgeNames + pantryNames).prefix(6)
        let moreCount = dataManager.fridgeItems.count + dataManager.pantryItems.count - combined.count
        
        if combined.isEmpty {
            return "No ingredients available"
        }
        
        var text = combined.joined(separator: ", ")
        if moreCount > 0 {
            text += " +\(moreCount) more"
        }
        return text
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppNavigationState())
}
