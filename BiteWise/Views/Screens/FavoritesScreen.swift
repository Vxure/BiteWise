import SwiftUI

struct FavoritesScreen: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var isVisible = false
    
    private var favoriteRecipes: [Recipe] {
        dataManager.favoriteRecipes
    }
    
    var body: some View {
        ZStack {
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
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("My Favorites")
                            .font(BWTypography.sectionHeader)
                        
                        Spacer()
                        
                        if !favoriteRecipes.isEmpty {
                            Text("\(favoriteRecipes.count) saved")
                                .font(BWTypography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    if favoriteRecipes.isEmpty {
                        // Empty state
                        emptyStateView
                            .padding(.top, 60)
                    } else {
                        // Recipe cards
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteRecipes) { recipe in
                                FavoriteRecipeCard(recipe: recipe) {
                                    navigationState.navigateTo(.recipeDetail(recipe))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }
        }
        .customNavigation()
        .onAppear {
            isVisible = true
        }
        .refreshable {
            // Pull to refresh from cloud
            if authService.isAuthenticated {
                await dataManager.loadFromCloud()
            }
        }
        .overlay(alignment: .top) {
            // Show sync error if present
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.bwAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(Color.bwAccent.opacity(0.4))
            }
            
            VStack(spacing: 8) {
                Text("No favorites yet")
                    .font(BWTypography.cardTitle)
                    .foregroundColor(.primary)
                
                Text("Save recipes you love by tapping\nthe star icon on any recipe")
                    .font(BWTypography.bodySecondary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Card component for favorite recipes
struct FavoriteRecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var recipeColor: Color {
        if recipe.title.contains("Carbonara") || recipe.title.contains("Pasta") {
            return Color.bwAccent
        } else if recipe.title.contains("Stir Fry") || recipe.title.contains("Chicken") {
            return Color.bwPrimary
        } else if recipe.title.contains("Risotto") || recipe.title.contains("Mushroom") {
            return Color.bwProtein
        } else {
            return Color.bwPrimary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Recipe image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [recipeColor.opacity(0.25), recipeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: recipeIcon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(recipeColor)
                }
                
                // Recipe info
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(BWTypography.bodyPrimary)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(recipe.description)
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(recipe.prepTime + recipe.cookTime) min")
                                .font(BWTypography.captionSmall)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(recipe.macros.calories) cal")
                                .font(BWTypography.captionSmall)
                        }
                        .foregroundColor(Color.bwAccent)
                    }
                }
                
                Spacer()
                
                // Favorite button
                Button(action: {
                    BWHaptics.mediumImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dataManager.toggleFavorite(recipe)
                    }
                }) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.bwAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
            .adaptiveShadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.bwPressable)
    }
    
    private var recipeIcon: String {
        if recipe.title.contains("Carbonara") || recipe.title.contains("Pasta") {
            return "fork.knife"
        } else if recipe.title.contains("Stir Fry") {
            return "flame"
        } else if recipe.title.contains("Risotto") || recipe.title.contains("Mushroom") {
            return "leaf"
        } else if recipe.title.contains("Salad") {
            return "leaf.arrow.triangle.circlepath"
        } else if recipe.title.contains("Omelet") || recipe.title.contains("Egg") {
            return "sun.max"
        } else if recipe.title.contains("Yogurt") || recipe.title.contains("Parfait") {
            return "cup.and.saucer"
        } else {
            return "fork.knife"
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesScreen()
            .environmentObject(AppNavigationState())
    }
}

