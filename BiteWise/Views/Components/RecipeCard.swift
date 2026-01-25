import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder with gradient overlay
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [recipeColor.opacity(0.25), recipeColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                
                Image(systemName: recipeIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .foregroundColor(recipeColor.opacity(0.6))
            }
            
            // Title
            Text(recipe.title)
                .font(BWTypography.cardTitle)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Description
            Text(recipe.description)
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Macro badges and time
            HStack(spacing: 6) {
                MacroBadge(label: "P", value: recipe.macros.protein, type: .protein)
                MacroBadge(label: "C", value: recipe.macros.carbs, type: .carbs)
                MacroBadge(label: "F", value: recipe.macros.fats, type: .fats)
                
                Spacer()
                
                // Time badge
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text("\(recipe.prepTime + recipe.cookTime) min")
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: colorScheme == .dark ? .clear : recipeColor.opacity(0.12), radius: 16, x: 0, y: 8)
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    
    // Determine recipe color based on title
    private var recipeColor: Color {
        if recipe.title.contains("Carbonara") || recipe.title.contains("Pasta") {
            return Color.bwCarbs
        } else if recipe.title.contains("Stir Fry") || recipe.title.contains("Chicken") {
            return Color.bwPrimary
        } else if recipe.title.contains("Risotto") || recipe.title.contains("Mushroom") {
            return Color.bwProtein
        } else {
            return Color.bwPrimary
        }
    }
    
    // Determine recipe icon based on title
    private var recipeIcon: String {
        if recipe.title.contains("Carbonara") || recipe.title.contains("Pasta") {
            return "fork.knife"
        } else if recipe.title.contains("Stir Fry") {
            return "flame.fill"
        } else if recipe.title.contains("Risotto") || recipe.title.contains("Mushroom") {
            return "leaf.fill"
        } else {
            return "fork.knife"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        RecipeCard(recipe: Recipe.dummyData[0])
        RecipeCard(recipe: Recipe.dummyData[1])
    }
    .padding()
    .bwBackground()
}
