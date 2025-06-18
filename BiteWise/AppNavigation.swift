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
    case dailyMacroGoals
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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingFlow(onComplete: {
                hasCompletedOnboarding = true
            })
        } else {
            MainTabView()
                .environmentObject(navigationState)
        }
    }
}

// Onboarding flow with welcome and pantry setup
struct OnboardingFlow: View {
    @StateObject private var navigationState = AppNavigationState()
    var onComplete: () -> Void
    
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
                        // Complete onboarding when user finishes pantry setup
                        onComplete()
                    }
                
                default:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(navigationState)
        }
    }
}

// Custom floating tab bar
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let tabItems: [(image: String, title: String)]
    @Namespace private var animation
    
    var body: some View {
        // Wrap in VStack to ensure it only affects the bottom
        VStack {
            Spacer() // Push everything to the bottom
            
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tabItems[index].image)
                                .font(.system(size: 22))
                                .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                            
                            Text(tabItems[index].title)
                                .font(.caption2)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                            
                            // Indicator for selected tab
                            ZStack {
                                if selectedTab == index {
                                    Circle()
                                        .fill(Color(hex: "4285F4"))
                                        .frame(width: 5, height: 5)
                                        .matchedGeometryEffect(id: "TAB_INDICATOR", in: animation)
                                }
                            }
                            .frame(height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTab == index ? Color(hex: "4285F4") : .gray)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(
                tabBarBackground
            )
            .cornerRadius(32)
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1) // Additional subtle shadow for depth
            .padding(.horizontal, 40)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    @ViewBuilder
    private var tabBarBackground: some View {
        if #available(iOS 15.0, *) {
            Rectangle()
                .fill(.ultraThinMaterial)
        } else {
            Rectangle()
                .fill(Color.white.opacity(0.7))
                .blur(radius: 3)
        }
    }
}

// Main tab view after onboarding is complete
struct MainTabView: View {
    @StateObject private var dashboardNavigationState = AppNavigationState()
    @StateObject private var scanNavigationState = AppNavigationState()
    @StateObject private var assistantNavigationState = AppNavigationState()
    @StateObject private var settingsNavigationState = AppNavigationState()
    @State private var selectedTab = 0
    
    // Tab items data
    private let tabItems = [
        (image: "house", title: "Dashboard"),
        (image: "camera", title: "Scan"),
        (image: "sparkles", title: "Assistant"),
        (image: "gear", title: "Settings")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                NavigationStack(path: $dashboardNavigationState.path) {
                    DashboardView()
                        .navigationDestination(for: AppScreen.self) { screen in
                            navigationDestination(for: screen, navigationState: dashboardNavigationState)
                        }
                        .navigationBarTitleDisplayMode(.inline)
                }
                .environmentObject(dashboardNavigationState)
                .tag(0)
                
                // Scan Tab
                NavigationStack(path: $scanNavigationState.path) {
                    PhotoUploadScreen {
                        scanNavigationState.navigateTo(.detectedIngredients)
                    }
                    .navigationDestination(for: AppScreen.self) { screen in
                        navigationDestination(for: screen, navigationState: scanNavigationState)
                    }
                    .navigationTitle("Scan")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .environmentObject(scanNavigationState)
                .tag(1)
                
                // Assistant Tab
                NavigationStack(path: $assistantNavigationState.path) {
                    RecipeAIIntroView {
                        // Handle assistant action
                    }
                    .navigationDestination(for: AppScreen.self) { screen in
                        navigationDestination(for: screen, navigationState: assistantNavigationState)
                    }
                    .navigationTitle("Assistant")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .environmentObject(assistantNavigationState)
                .tag(2)
                
                // Settings Tab
                NavigationStack(path: $settingsNavigationState.path) {
                    SettingsView(navigationState: settingsNavigationState)
                        .navigationDestination(for: AppScreen.self) { screen in
                            navigationDestination(for: screen, navigationState: settingsNavigationState)
                        }
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .environmentObject(settingsNavigationState)
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(Color.clear) // Ensure TabView has clear background
            
            // Custom floating tab bar
            FloatingTabBar(selectedTab: $selectedTab, tabItems: tabItems)
        }
        .ignoresSafeArea() // Ignore safe area on all edges
    }
    
    @ViewBuilder
    private func navigationDestination(for screen: AppScreen, navigationState: AppNavigationState) -> some View {
        switch screen {
        case .welcome:
            WelcomeScreen {
                navigationState.navigateTo(.pantrySetup)
            }
        
        case .pantrySetup:
            PantrySetupScreen {
                navigationState.navigateBack()
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
        
        case .dailyMacroGoals:
            DailyMacroGoalsScreen()
        }
    }
}

// Settings View
struct SettingsView: View {
    var navigationState: AppNavigationState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        List {
            Section(header: Text("Profile")) {
                Button(action: {
                    navigationState.navigateTo(.userProfile)
                }) {
                    Label("User Profile", systemImage: "person")
                }
            }
            
            Section(header: Text("Preferences")) {
                Button(action: {
                    navigationState.navigateTo(.pantrySetup)
                }) {
                    Label("Edit Pantry Items", systemImage: "list.bullet")
                }
                
                Button(action: {
                    // Reset onboarding flag to show onboarding again
                    hasCompletedOnboarding = false
                }) {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                }
            }
            
            Section(header: Text("Feedback")) {
                Button(action: {
                    navigationState.navigateTo(.feedback)
                }) {
                    Label("Send Feedback", systemImage: "envelope")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

#Preview {
    AppNavigation()
} 
 