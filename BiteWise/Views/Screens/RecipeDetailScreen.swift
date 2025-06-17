import SwiftUI

struct RecipeDetailScreen: View {
    let recipe: Recipe
    var onFeedback: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Image placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60)
                            .foregroundColor(.gray.opacity(0.5))
                    )
                
                // Recipe title
                Text(recipe.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Time info
                HStack {
                    Label("\(recipe.prepTime) min prep", systemImage: "clock")
                        .font(.caption)
                    
                    Spacer()
                    
                    Label("\(recipe.cookTime) min cook", systemImage: "flame")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Macro nutrients
                HStack {
                    MacroBadge(label: "Protein", value: recipe.macros.protein, type: .protein)
                    MacroBadge(label: "Carbs", value: recipe.macros.carbs, type: .carbs)
                    MacroBadge(label: "Fats", value: recipe.macros.fats, type: .fats)
                    
                    Spacer()
                    
                    Text("\(recipe.macros.calories) cal")
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Ingredients section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients")
                        .font(.headline)
                    
                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        HStack(alignment: .top) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(ingredient)
                        }
                    }
                }
                
                // Steps section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Steps")
                        .font(.headline)
                    
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(index + 1)")
                                .font(.body.bold())
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.green))
                            
                            Text(step)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                // Feedback button
                Button(action: onFeedback) {
                    Text("Leave Feedback")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.vertical)
            }
            .padding()
        }
    }
}

#Preview {
    RecipeDetailScreen(recipe: Recipe.dummyData[0], onFeedback: {})
} 