import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Bookmark Position Preference Key
private struct BookmarkPositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Tooltip Arrow
private struct TooltipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct RecipeDetailScreen: View {
    let recipe: Recipe
    var onFeedback: () -> Void
    @State private var userRating: Int = 0
    @State private var showingAIAssistant: Bool = false
    @State private var showingCookingInstructions: Bool = false
    @State private var showingDeductionAlert: Bool = false
    @State private var deductedItems: [String] = []
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // FTUE tutorial overlay state
    @AppStorage("hasSeenSaveTip") private var hasSeenSaveTip: Bool = false
    @State private var showTutorialOverlay: Bool = false
    @State private var overlayOpacity: Double = 0
    @State private var tooltipVisible: Bool = false
    @State private var bookmarkPulse: Bool = false
    @State private var bookmarkButtonFrame: CGRect = .zero
    
    // Pill-shaped confirmation toast state (original design)
    @State private var showSaveConfirmation: Bool = false
    @State private var checkmarkAnimated: Bool = false

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
            // Adaptive background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
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
                    
                    // Spacer for floating header (reduced to start content closer to fade)
                    Color.clear
                        .frame(height: headerHeight - 20)
                    
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
                        
                        // Save bookmark button
                        Button(action: { handleSaveTap() }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 44, height: 44)
                                    .adaptiveShadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                                Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.bwAdaptiveAccent(for: colorScheme))
                                    .scaleEffect(isFavorite ? 1.1 : 1.0)
                            }
                        }
                        .buttonStyle(.bwPressable)
                        .padding(12)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: BookmarkPositionKey.self,
                                        value: geo.frame(in: .global)
                                    )
                            }
                        )
                        .onPreferenceChange(BookmarkPositionKey.self) { frame in
                            bookmarkButtonFrame = frame
                        }
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
                    
                    // Start Cooking button
                    Button(action: {
                        BWHaptics.mediumImpact()
                        showingCookingInstructions = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Start Cooking")
                                .font(BWTypography.buttonLabel)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(BWGradients.primaryGradient(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .adaptiveShadow(color: Color.bwPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.bwPressable)
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
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 40, height: 40)
                                .adaptiveShadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
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
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(BWGradients.headerFadeGradient(for: colorScheme))
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)

            // MARK: - FTUE Tutorial Overlay
            if showTutorialOverlay {
                ZStack {
                    Color.black
                        .opacity(overlayOpacity * 0.55)
                        .ignoresSafeArea()
                        .onTapGesture { dismissTutorial() }

                    Button(action: { handleSaveTap() }) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.white.opacity(0.25), radius: 16, x: 0, y: 0)
                                .shadow(color: Color.bwAdaptiveAccent(for: colorScheme).opacity(0.3), radius: 20, x: 0, y: 4)

                            Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.bwAdaptiveAccent(for: colorScheme))
                        }
                        .scaleEffect(bookmarkPulse ? 1.08 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: bookmarkButtonFrame.midX,
                        y: bookmarkButtonFrame.midY - 60
                    )

                    if tooltipVisible {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                TooltipArrow()
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .frame(width: 16, height: 8)
                                    .padding(.trailing, 28)
                            }
                            .frame(maxWidth: 280)

                            HStack(spacing: 8) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.bwAdaptiveAccent(for: colorScheme))

                                Text("Sound yummy? Save this for later!")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
                        }
                        .position(
                            x: bookmarkButtonFrame.midX - 105,
                            y: bookmarkButtonFrame.maxY - 35
                        )
                        .transition(.opacity.combined(with: .offset(y: -8)).combined(with: .scale(scale: 0.95)))
                    }
                }
                .zIndex(10)
                .animation(.easeOut(duration: 0.35), value: overlayOpacity)
                .animation(.bwBouncy, value: tooltipVisible)
                .allowsHitTesting(true)
            }

            // MARK: - Save Confirmation Toast (pill above nav bar)
            if showSaveConfirmation {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .scaleEffect(checkmarkAnimated ? 1.0 : 0.0)
                        .opacity(checkmarkAnimated ? 1.0 : 0.0)
                        .animation(.bwBouncy, value: checkmarkAnimated)
                    Text("Saved. We'll remember this for later.")
                        .font(BWTypography.caption)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                .padding(.bottom, 110)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
                .zIndex(2)
                .allowsHitTesting(false)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showingAIAssistant) {
            ChatbotScreen(recipe: recipe) {
                showingAIAssistant = false
            }
        }
        .fullScreenCover(isPresented: $showingCookingInstructions) {
            CookingInstructionsScreen(recipe: recipe) {
                showingCookingInstructions = false
            }
        }
        .alert("Ingredients Removed", isPresented: $showingDeductionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if deductedItems.isEmpty {
                Text("Recipe marked as cooked! No matching ingredients were found in your inventory.")
            } else {
                Text("Recipe marked as cooked!\n\nRemoved from ingredients:\n\(deductedItems.joined(separator: ", "))")
            }
        }
        .onAppear {
            hasSeenSaveTip = false
            userRating = dataManager.getRating(for: recipe)
            if !hasSeenSaveTip && !isFavorite {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    presentTutorial()
                }
            }
        }
        .onChange(of: showSaveConfirmation) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.bwSnappy) { showSaveConfirmation = false }
                }
            }
        }
    }
    
    // MARK: - FTUE Tutorial Lifecycle
    
    private func presentTutorial() {
        showTutorialOverlay = true
        withAnimation(.easeOut(duration: 0.4)) {
            overlayOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                tooltipVisible = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bookmarkPulse = true
            }
        }
    }
    
    private func dismissTutorial() {
        withAnimation(.easeOut(duration: 0.25)) {
            tooltipVisible = false
            bookmarkPulse = false
        }
        withAnimation(.easeOut(duration: 0.3)) {
            overlayOpacity = 0
        }
        hasSeenSaveTip = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showTutorialOverlay = false
        }
    }
    
    private func handleSaveTap() {
        BWHaptics.mediumImpact()
        let wasFavorite = isFavorite
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            dataManager.toggleFavorite(recipe)
        }
        
        if showTutorialOverlay {
            dismissTutorial()
        }
        
        if !wasFavorite {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkmarkAnimated = false
                BWHaptics.success()
                withAnimation(.bwBouncy) { showSaveConfirmation = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.bwBouncy) { checkmarkAnimated = true }
                }
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
