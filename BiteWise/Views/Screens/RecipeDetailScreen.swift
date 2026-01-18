import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct RecipeDetailScreen: View {
    let recipe: Recipe
    var onFeedback: () -> Void
    @State private var userRating: Int = 0
    @State private var showingAIAssistant: Bool = false
    @State private var showingDeductionAlert: Bool = false
    @State private var deductedItems: [String] = []
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration
    private let headerHeight: CGFloat = 50
    
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
    
    private var isFavorite: Bool {
        dataManager.isFavorite(recipe)
    }
    
    private var isMarkedAsCooked: Bool {
        dataManager.isCooked(recipe)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                    
                    // Recipe image placeholder with color matching the recipe
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [recipeColor.opacity(0.3), recipeColor.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .aspectRatio(16/9, contentMode: .fit)
                            
                            Image(systemName: recipeIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60)
                                .foregroundColor(recipeColor)
                        }
                        
                        // Favorite star button
                        Button(action: {
                            BWHaptics.mediumImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dataManager.toggleFavorite(recipe)
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.bwAccent)
                                    .scaleEffect(isFavorite ? 1.1 : 1.0)
                            }
                        }
                        .buttonStyle(.bwPressable)
                        .padding(12)
                    }
                    
                    // Recipe title and description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.bwLargeTitle())
                        
                        Text(recipe.description)
                            .font(.bwBody())
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Time info card
                    HStack(spacing: 16) {
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(recipeColor)
                            Text("\(recipe.prepTime) min prep")
                                .font(BWTypography.caption)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 5) {
                            Image(systemName: "flame")
                                .font(.system(size: 14))
                                .foregroundColor(recipeColor)
                            Text("\(recipe.cookTime) min cook")
                                .font(BWTypography.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                    .bwCardStyle(padding: 14, cornerRadius: 16)
                    
                    // Macro nutrients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition Facts")
                            .font(BWTypography.cardTitle)
                        
                        HStack(spacing: 8) {
                            MacroBadge(label: "P", value: recipe.macros.protein, type: .protein)
                            MacroBadge(label: "C", value: recipe.macros.carbs, type: .carbs)
                            MacroBadge(label: "F", value: recipe.macros.fats, type: .fats)
                            
                            Spacer()
                            
                            // Calories badge with pastel red/pink
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.red.opacity(0.8))
                                Text("\(recipe.macros.calories)cal")
                                    .font(BWTypography.captionSmall)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.red.opacity(0.8))
                            }
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    .bwCardStyle(padding: 14, cornerRadius: 16)
                    
                    // Ingredients section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(BWTypography.cardTitle)
                        
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .center, spacing: 10) {
                                Circle()
                                    .fill(recipeColor)
                                    .frame(width: 6, height: 6)
                                
                                Text(ingredient)
                                    .font(BWTypography.bodyPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bwCardStyle(padding: 14, cornerRadius: 16)
                    
                    // Steps section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Steps")
                            .font(BWTypography.cardTitle)
                        
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(BWTypography.captionSmall)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [recipeColor, recipeColor.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                
                                Text(step)
                                    .font(BWTypography.bodyPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bwCardStyle(padding: 14, cornerRadius: 16)
                    
                    // Rating section
                    HStack {
                        Text("Rate this Recipe")
                            .font(BWTypography.cardTitle)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= userRating ? "star.fill" : "star")
                                    .foregroundColor(star <= userRating ? .yellow : .gray.opacity(0.4))
                                    .font(.title3)
                                    .scaleEffect(star <= userRating ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userRating)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            userRating = star
                                            dataManager.setRating(for: recipe, rating: star)
                                        }
                                    }
                            }
                        }
                    }
                    .bwCardStyle(padding: 14, cornerRadius: 16)
                    
                    // Mark as cooked button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if !isMarkedAsCooked {
                                // Mark as cooked and deduct ingredients
                                dataManager.markAsCooked(recipe)
                                deductedItems = dataManager.deductIngredients(for: recipe)
                                BWHaptics.success()
                                showingDeductionAlert = true
                            } else {
                                // Just unmark as cooked (don't restore ingredients)
                                dataManager.unmarkAsCooked(recipe)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: isMarkedAsCooked ? "checkmark.circle.fill" : "circle")
                            Text(isMarkedAsCooked ? "Marked as Cooked" : "Mark as Cooked")
                        }
                        .font(.bwHeadline())
                        .foregroundColor(isMarkedAsCooked ? .white : recipeColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if isMarkedAsCooked {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [recipeColor, recipeColor.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(recipeColor, lineWidth: 2)
                                }
                            }
                        )
                        .shadow(color: isMarkedAsCooked ? recipeColor.opacity(0.4) : .clear, radius: 8, y: 4)
                    }
                    .scaleEffect(isMarkedAsCooked ? 1.02 : 1.0)
                    
                    // Refine with AI button
                    GradientButton(
                        icon: "sparkles",
                        text: "Refine Recipe with AI",
                        action: { showingAIAssistant = true }
                    )
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            
            // MARK: - Floating Header Overlay
            VStack(spacing: 0) {
                HStack {
                    // Back button
                    Button(action: {
                        BWHaptics.lightImpact()
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.bwPrimary)
                        }
                    }
                    .buttonStyle(.bwPressable)
                    
                    Spacer()
                    
                    Text(recipe.title)
                        .font(BWTypography.cardTitle)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
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
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showingAIAssistant) {
            // Go directly to ChatbotScreen with recipe context (skip intro)
            ChatbotScreen(recipe: recipe) {
                showingAIAssistant = false
            }
        }
        .alert("Ingredients Removed", isPresented: $showingDeductionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if deductedItems.isEmpty {
                Text("Recipe marked as cooked! No matching ingredients were found in your inventory.")
            } else {
                Text("Recipe marked as cooked!\n\nRemoved from pantry:\n\(deductedItems.joined(separator: ", "))")
            }
        }
        .onAppear {
            // Load saved rating
            userRating = dataManager.getRating(for: recipe)
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
    
    // Determine recipe color based on title
    private var recipeColor: Color {
        if recipe.title.contains("Carbonara") {
            return Color.bwPrimaryCoral
        } else if recipe.title.contains("Stir Fry") {
            return Color.bwAccentGreen
        } else if recipe.title.contains("Risotto") {
            return Color.bwAccentGold
        } else {
            return Color.bwAccentGreen
        }
    }
    
    // Determine recipe icon based on title
    private var recipeIcon: String {
        if recipe.title.contains("Carbonara") {
            return "fork.knife"
        } else if recipe.title.contains("Stir Fry") {
            return "flame"
        } else if recipe.title.contains("Risotto") {
            return "leaf"
        } else {
            return "fork.knife"
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailScreen(recipe: Recipe.dummyData[3], onFeedback: {})
    }
}
