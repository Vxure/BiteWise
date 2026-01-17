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
    @State private var isVisible = false
    @AppStorage("hasSeenWelcomeHint") private var hasSeenWelcomeHint: Bool = false
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
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
            // Enhanced gradient background
            BWGradients.backgroundGradient
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
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color.bwGradientCream, location: 0),
                        .init(color: Color.bwGradientCream, location: 0.6),
                        .init(color: Color.bwGradientCream.opacity(0.8), location: 0.75),
                        .init(color: Color.bwGradientCream.opacity(0), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
        }
        .onAppear {
            isVisible = true
        }
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
            
            Spacer()
            
            // Favorites button
            Button(action: {
                BWHaptics.lightImpact()
                navigationState.navigateTo(.favorites)
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.bwAccent.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: dataManager.hasFavorites ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.bwAccent)
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
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.bwPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.bwPrimary)
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
                .fill(Color.white)
                .shadow(color: Color.bwPrimary.opacity(0.1), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.bwPrimary.opacity(0.1), lineWidth: 1)
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
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
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
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                )
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
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
                            .foregroundColor(Color.bwPrimary)
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
                                    colors: [Color.bwPrimary.opacity(0.15), Color.bwPrimary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "cabinet.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwPrimary)
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
                            .foregroundColor(Color.bwPrimary.opacity(0.8))
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
                                .fill(Color.bwPrimary)
                        )
                        .shadow(color: Color.bwPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.bwPressable)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                )
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
                            .foregroundColor(Color.bwAccentBlue)
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
                                    colors: [Color.bwAccentBlue.opacity(0.15), Color.bwAccentBlue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "refrigerator.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.bwAccentBlue)
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
                                .foregroundColor(Color.bwAccentBlue.opacity(0.8))
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
                                .fill(Color.bwAccentBlue)
                        )
                        .shadow(color: Color.bwAccentBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.bwPressable)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                )
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
                    navigationState.navigateTo(.dailyMacroGoals)
                }) {
                    macroCardView(
                        title: "Calories",
                        value: "\(caloriesConsumed)",
                        goal: "of \(calorieGoal)",
                        progress: calorieProgress,
                        icon: "flame.fill",
                        color: Color.bwAccent
                    )
                }
                .buttonStyle(.bwPressable)
                
                // Protein card with animated progress
                Button(action: {
                    BWHaptics.lightImpact()
                    navigationState.navigateTo(.dailyMacroGoals)
                }) {
                    macroCardView(
                        title: "Protein",
                        value: "\(proteinConsumed)g",
                        goal: "of \(proteinGoalGrams)g",
                        progress: proteinProgress,
                        icon: "leaf.fill",
                        color: Color.bwPrimary
                    )
                }
                .buttonStyle(.bwPressable)
            }
        }
        .bwCardStyle(padding: 14, cornerRadius: 16)
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
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                )
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
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
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                )
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

#Preview {
    DashboardView()
        .environmentObject(AppNavigationState())
}
