import SwiftUI 

// Navigation path used to keep track of screen stack
enum AppScreen: Hashable {
    case welcome
    case pantrySetup
    case photoUpload
    case detectedIngredients
    case recipeSuggestion
    case recipeDetail(Recipe)
    case recipeAIAssistant
    case feedback
    case userProfile
}

class AppNavigationState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedRecipe: Recipe?
    
    func navigateTo(_ screen: AppScreen) {
        path.append(screen)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
}

struct AppNavigation: View {
    @StateObject private var navigationState = AppNavigationState()
    
    var body: some View {
        NavigationStack(path: $navigationState.path) {
            WelcomeScreen {
                navigationState.navigateTo(.pantrySetup)
            }
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .welcome:
                    WelcomeScreen {
                        navigationState.navigateTo(.pantrySetup)
                    }
                
                case .pantrySetup:
                    PantrySetupScreen {
                        navigationState.navigateTo(.photoUpload)
                    }
                
                case .photoUpload:
                    PhotoUploadScreen {
                        navigationState.navigateTo(.detectedIngredients)
                    }
                
                case .detectedIngredients:
                    DetectedIngredientsScreen {
                        navigationState.navigateTo(.recipeSuggestion)
                    }
                
                case .recipeSuggestion:
                    RecipeSuggestionScreen(
                        onRecipeSelected: { recipe in
                            navigationState.selectedRecipe = recipe
                            navigationState.navigateTo(.recipeDetail(recipe))
                        }
                    )
                
                case .recipeDetail(let recipe):
                    RecipeDetailScreen(recipe: recipe) {
                        navigationState.navigateTo(.feedback)
                    }
                
                case .recipeAIAssistant:
                    RecipeAIIntroView {
                        navigationState.navigateBack()
                    }
                
                case .feedback:
                    FeedbackScreen {
                        // After feedback, go back to recipe suggestion
                        navigationState.navigateTo(.recipeSuggestion)
                    }
                
                case .userProfile:
                    UserProfileScreen {
                        navigationState.navigateBack()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(navigationState)
        }
    }
}

#Preview {
    AppNavigation()
} 
