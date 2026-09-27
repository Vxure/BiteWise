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
    @EnvironmentObject private var tabSelection: TabSelectionState
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var guestModeService = GuestModeService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var isVisible = false
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

    // MARK: - Hero Section Data

    private var totalItems: Int {
        dataManager.fridgeItems.count + dataManager.pantryItems.count
    }

    private var heroRecipes: [Recipe] {
        if !dataManager.latestGeneratedRecipes.isEmpty {
            return Array(dataManager.latestGeneratedRecipes.prefix(8))
        }
        if !dataManager.recipeHistory.isEmpty {
            return Array(dataManager.recipeHistory.prefix(8))
        }
        return Recipe.dummyData
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
                    
                    // Spacer for the floating header (reduced to start content closer to fade)
                    Color.clear
                        .frame(height: headerHeight - 30)
                    
                    // MARK: - Greeting Header (simplified)
                    greetingHeaderSection
                        .staggeredAppear(index: 0)
                    
                    // MARK: - Hero Section (conditional)
                    heroSection
                        .staggeredAppear(index: 1)
                        .animation(.bwSpring, value: totalItems == 0)
                    
                    // MARK: - My Kitchen (Pantry + Fridge)
                    inventorySection
                        .staggeredAppear(index: 3)
                    
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
                    .padding(.bottom, 12)
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
                
                // Migrate guest data BEFORE loading from cloud
                // This is a fallback for the AuthView returning user flow
                if guestModeService.wasInGuestMode {
                    let migrationSucceeded = await dataManager.migrateGuestDataOnFirstAuth()
                    // Only clear flag if migration succeeded, so it can be retried on failure
                    if migrationSucceeded {
                        guestModeService.clearWasInGuestMode()
                    }
                }
                
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
            
            // Saved recipes button
            Button(action: {
                BWHaptics.lightImpact()
                navigationState.navigateTo(.favorites)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 44, height: 44)
                        .adaptiveShadow(color: Color.bwAdaptiveAccent(for: colorScheme).opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: dataManager.hasFavorites ? "bookmark.fill" : "bookmark")
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
        let displayName = dataManager.userProfile.name
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(greetingEmoji) Good \(timeOfDay)\(displayName.isEmpty ? "!" : ", \(displayName)!")")
                .font(BWTypography.cardTitle)
                .foregroundColor(.primary)
            
            Text("Ready to cook something good?")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 14, cornerRadius: 16)
    }

    // MARK: - Hero Section (conditional router)

    @ViewBuilder
    private var heroSection: some View {
        if totalItems == 0 {
            heroEmptyStateCard
        } else {
            heroRecipeCarousel
        }
    }

    // MARK: - Hero Empty State (State A: totalItems == 0)

    private var heroEmptyStateCard: some View {
        VStack(spacing: 16) {
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
                    .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
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

            Button(action: {
                BWHaptics.mediumImpact()
                tabSelection.switchToTab(1)
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

    // MARK: - Hero Recipe Carousel (State B: totalItems > 0)

    private var heroRecipeCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Based on your ingredients")
                        .font(BWTypography.cardTitle)

                    Text("Recipes using the \(totalItems) items in your kitchen")
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    BWHaptics.lightImpact()
                    let sessionContext = SessionContext.shared
                    if !sessionContext.restoreLatestRecipes() {
                        sessionContext.showRecipes(Array(dataManager.recipeHistory))
                    }
                    navigationState.navigateTo(.recipeSuggestion)
                }) {
                    Text("View All")
                        .font(BWTypography.buttonSmall)
                        .foregroundColor(Color.bwPrimary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(heroRecipes.enumerated()), id: \.element.id) { index, recipe in
                        Button(action: {
                            BWHaptics.lightImpact()
                            navigationState.navigateTo(.recipeDetail(recipe))
                        }) {
                            heroRecipeCard(recipe: recipe, index: index)
                        }
                        .buttonStyle(.bwPressable)
                    }
                }
                .padding(.bottom, 4)
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Hero Recipe Card

    private func heroRecipeCard(recipe: Recipe, index: Int) -> some View {
        let cardColor = colorForRecipe(at: index)
        let cardIcon = iconForRecipe(at: index)

        return VStack(alignment: .leading, spacing: 0) {
            // Gradient placeholder image
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
                .fill(
                    LinearGradient(
                        colors: [cardColor.opacity(0.25), cardColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 110)

                Image(systemName: cardIcon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(cardColor)
            }

            // Card info
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(BWTypography.cardTitle)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    CompactMacroBadge(value: recipe.macros.carbs, type: .carbs)
                    CompactMacroBadge(value: recipe.macros.protein, type: .protein)
                    CompactMacroBadge(value: recipe.macros.fats, type: .fats)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
        .adaptiveShadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Saved Recipes Preview
    private var favoritesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Recipes")
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
                        
                        Image(systemName: "bookmark")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwAccent.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No saved recipes yet")
                            .font(BWTypography.bodyPrimary)
                            .fontWeight(.medium)
                        
                        Text("Save recipes you love by tapping the bookmark icon")
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
                
                Image(systemName: "bookmark.fill")
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
    
    // MARK: - My Kitchen (Combined Pantry + Fridge)
    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Kitchen")
                .font(BWTypography.cardTitle)

            HStack(spacing: 12) {
                // Pantry sub-card
                inventorySubCard(
                    title: "Pantry",
                    icon: "archivebox.fill",
                    color: Color.bwPantryBrown,
                    itemCount: dataManager.pantryItems.count,
                    lastUpdate: dataManager.lastPantryUpdateTimeAgo,
                    onTap: { navigationState.navigateTo(.pantryItems) },
                    onScan: { tabSelection.switchToTab(1) }
                )

                // Fridge sub-card
                inventorySubCard(
                    title: "Fridge",
                    icon: "snowflake",
                    color: Color.bwFridgeBlue,
                    itemCount: dataManager.fridgeItems.count,
                    lastUpdate: dataManager.lastFridgeScanTimeAgo,
                    onTap: { navigationState.navigateTo(.fridgeItems) },
                    onScan: { tabSelection.switchToTab(1) }
                )
            }
        }
        .bwCardStyle(padding: 16, cornerRadius: 20)
    }

    private func inventorySubCard(
        title: String,
        icon: String,
        color: Color,
        itemCount: Int,
        lastUpdate: String?,
        onTap: @escaping () -> Void,
        onScan: @escaping () -> Void
    ) -> some View {
        Button(action: {
            BWHaptics.lightImpact()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.2), color.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(color)
                    }

                    Spacer()

                    Button(action: {
                        BWHaptics.lightImpact()
                        onScan()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .buttonStyle(.bwPressable)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(itemCount) items")
                        .font(BWTypography.bodyPrimary)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if let timeAgo = lastUpdate {
                        Text("Updated \(timeAgo)")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(color.opacity(0.8))
                    } else {
                        Text("Tap to manage")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.tertiarySystemBackground))
            )
            .adaptiveShadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
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
                        tabSelection.switchToTab(1)
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
        .environmentObject(TabSelectionState())
}
