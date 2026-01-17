import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct RecipeSuggestionScreen: View {
    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAIAssistant = false
    @ObservedObject private var sessionContext = SessionContext.shared
    @ObservedObject private var dataManager = DataManager.shared
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration
    private let headerHeight: CGFloat = 100
    
    var onRecipeSelected: (Recipe) -> Void
    
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
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            // Main content - ScrollView with proper bottom padding
            ScrollView {
                VStack(spacing: 20) {
                    // Invisible anchor for scroll offset tracking
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                    }
                    .frame(height: 0)
                    
                    // Spacer for floating header
                    Color.clear
                        .frame(height: headerHeight)
                    
                    if isLoading {
                        // Loading state
                        VStack(spacing: 16) {
                            Spinner()
                            Text("Generating recipes...")
                                .font(.bwSubheadline())
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else if let error = errorMessage {
                        // Error state
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(Color.bwAccentOrange)
                            
                            Text(error)
                                .font(.bwSubheadline())
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Try Again") {
                                loadRecipes()
                            }
                            .font(.bwHeadline())
                            .foregroundColor(Color.bwPrimaryCoral)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        .padding(.horizontal, 40)
                    } else {
                        // Recipe cards
                        LazyVStack(spacing: 16) {
                            ForEach(recipes) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        onRecipeSelected(recipe)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                // Add padding at the bottom so last recipe isn't hidden behind button
                .padding(.bottom, 160)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            
            // MARK: - Floating Header Overlay
            VStack(spacing: 8) {
                Text("Recipe Suggestions")
                    .font(BWTypography.sectionHeader)
                
                // Dynamic subtitle based on state
                if !isLoading && errorMessage == nil && !recipes.isEmpty {
                    // Celebration message when recipes are loaded
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.bwPrimary)
                        
                        Text("Found \(recipes.count) recipe\(recipes.count == 1 ? "" : "s") for you!")
                            .font(.bwSubheadline())
                            .fontWeight(.medium)
                            .foregroundColor(Color.bwPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.bwPrimary.opacity(0.1))
                    )
                } else {
                    Text("Based on your ingredients")
                        .font(.bwSubheadline())
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 24)
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
            
            // Fixed floating button at bottom (hide when loading or error)
            if !isLoading && errorMessage == nil {
                VStack {
                    Spacer()
                    GradientButton(
                        icon: "paperplane.fill",
                        text: "Refine Recipes with AI",
                        action: { showingAIAssistant = true }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 75)
                }
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            RecipeAIIntroView {
                showingAIAssistant = false
            }
        }
        .customNavigation()
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            if recipes.isEmpty {
                loadRecipes()
            }
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
    
    /// Load recipes from GeminiService
    private func loadRecipes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get ingredients from session context
                let ingredientNames = sessionContext.ingredientNamesForRecipes
                
                // Get pantry items from DataManager
                let pantryItemNames = dataManager.pantryItems.map { $0.name }
                
                // Get user profile for preferences
                let userProfile = dataManager.userProfile
                
                // Generate recipes with both fresh ingredients AND pantry staples
                let generatedRecipes = try await GeminiService.shared.generateRecipes(
                    ingredients: ingredientNames,
                    pantryItems: pantryItemNames,
                    userProfile: userProfile
                )
                
                await MainActor.run {
                    recipes = generatedRecipes
                    sessionContext.generatedRecipes = generatedRecipes
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    RecipeSuggestionScreen(
        onRecipeSelected: { _ in }
    )
}
