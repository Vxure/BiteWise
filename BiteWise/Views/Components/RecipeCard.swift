import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    Image(systemName: "fork.knife")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .foregroundColor(.gray.opacity(0.5))
                )
                .aspectRatio(16/9, contentMode: .fit)
            
            Text(recipe.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(recipe.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                MacroBadge(label: "P", value: recipe.macros.protein, type: .protein)
                MacroBadge(label: "C", value: recipe.macros.carbs, type: .carbs)
                MacroBadge(label: "F", value: recipe.macros.fats, type: .fats)
                
                Spacer()
                
                Text("\(recipe.prepTime + recipe.cookTime) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    RecipeCard(recipe: Recipe.dummyData[0])
        .padding()
        .background(Color.gray.opacity(0.1))
} 