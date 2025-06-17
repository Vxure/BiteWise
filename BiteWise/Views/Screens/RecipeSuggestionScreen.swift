import SwiftUI

struct RecipeSuggestionScreen: View {
    let recipes: [Recipe] = Recipe.dummyData
    var onRecipeSelected: (Recipe) -> Void
    var onChatbot: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recipe Suggestions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Based on your ingredients")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(recipes) { recipe in
                        RecipeCard(recipe: recipe)
                            .onTapGesture {
                                onRecipeSelected(recipe)
                            }
                    }
                }
                .padding()
            }
            
            Button(action: onChatbot) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Refine with Chatbot")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
        }
    }
}

#Preview {
    RecipeSuggestionScreen(
        onRecipeSelected: { _ in },
        onChatbot: {}
    )
} 