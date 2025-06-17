import SwiftUI

struct RecipeSuggestionScreen: View {
    let recipes: [Recipe] = Recipe.dummyData
    var onRecipeSelected: (Recipe) -> Void
    @State private var showingAIAssistant = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    Text("Recipe Suggestions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Based on your ingredients")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    // Recipe cards
                    LazyVStack(spacing: 16) {
                        ForEach(recipes) { recipe in
                            RecipeCard(recipe: recipe)
                                .onTapGesture {
                                    onRecipeSelected(recipe)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                // Add padding at the bottom to ensure content isn't hidden behind the floating button
                .padding(.bottom, 100)
            }
            
            // Floating button with background
            VStack(spacing: 0) {
                // Using GradientButton component
                GradientButton(
                    icon: "paperplane.fill",
                    text: "Refine Recipes with AI",
                    action: { showingAIAssistant = true }
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
            }
            .background(
                Rectangle()
                    .fill(Color(UIColor.systemBackground).opacity(0.85))
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(height: 90)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, y: -2)
            )
        }
        .sheet(isPresented: $showingAIAssistant) {
            RecipeAIIntroView {
                showingAIAssistant = false
            }
        }
    }
}

#Preview {
    RecipeSuggestionScreen(
        onRecipeSelected: { _ in }
    )
} 