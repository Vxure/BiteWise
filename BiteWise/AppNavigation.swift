import SwiftUI 

// Navigation path used to keep track of screen stack
enum AppScreen: Hashable {
    case welcome
    case pantrySetup
    case macroGoalsOnboarding
    case onboardingCompletion
    case photoUpload
    case detectedIngredients
    case recipeSuggestion
    case recipeDetail(Recipe)
    case recipeAIAssistant
    case feedback
    case userProfile
    case dailyMacroGoals
    case favorites
    case fridgeItems
    case pantryItems
    case chatSettings
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
    @State private var initialTabAfterOnboarding: Int = 0
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingFlow(
                onComplete: {
                    initialTabAfterOnboarding = 0 // Dashboard tab
                    hasCompletedOnboarding = true
                },
                onCompleteWithScan: {
                    initialTabAfterOnboarding = 1 // Scan tab
                    hasCompletedOnboarding = true
                }
            )
        } else {
            MainTabView(initialTab: initialTabAfterOnboarding)
                .environmentObject(navigationState)
        }
    }
}

// Onboarding flow with welcome, pantry setup, macro goals, and completion
struct OnboardingFlow: View {
    @StateObject private var navigationState = AppNavigationState()
    var onComplete: () -> Void
    var onCompleteWithScan: (() -> Void)?
    
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
                        // Navigate to macro goals after pantry setup
                        navigationState.navigateTo(.macroGoalsOnboarding)
                    }
                
                case .macroGoalsOnboarding:
                    MacroGoalsOnboardingScreen(
                        onContinue: {
                            // Navigate to completion screen
                            navigationState.navigateTo(.onboardingCompletion)
                        },
                        onSkip: {
                            // Navigate to completion screen
                            navigationState.navigateTo(.onboardingCompletion)
                        }
                    )
                
                case .onboardingCompletion:
                    OnboardingCompletionScreen(
                        onComplete: {
                            // Go to dashboard
                            onComplete()
                        },
                        onScanNow: {
                            // Complete and go to scan tab
                            onCompleteWithScan?() ?? onComplete()
                        }
                    )
                
                default:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(navigationState)
        }
    }
}

// Custom floating tab bar with glow effects and animations
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let tabItems: [(image: String, title: String)]
    var onTabSelected: ((Int) -> Void)?
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    TabBarButton(
                        index: index,
                        selectedTab: $selectedTab,
                        item: tabItems[index],
                        namespace: animation,
                        onTabSelected: onTabSelected
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // Frosted glass effect
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                    
                    // Adaptive overlay - cream in light, darker in dark mode
                    RoundedRectangle(cornerRadius: 24)
                        .fill(colorScheme == .dark 
                              ? Color(.secondarySystemBackground).opacity(0.9)
                              : Color.bwSurface.opacity(0.85))
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            colorScheme == .dark 
                                ? Color.white.opacity(0.1)
                                : Color.white.opacity(0.6),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: colorScheme == .dark ? .clear : Color.black.opacity(0.08),
                radius: 16,
                x: 0,
                y: 6
            )
            .shadow(
                color: colorScheme == .dark ? .clear : Color.black.opacity(0.04),
                radius: 3,
                x: 0,
                y: 1
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

// Individual tab bar button with glow and animations
struct TabBarButton: View {
    let index: Int
    @Binding var selectedTab: Int
    let item: (image: String, title: String)
    var namespace: Namespace.ID
    var onTabSelected: ((Int) -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    private var isSelected: Bool { selectedTab == index }
    
    private var adaptivePrimary: Color {
        Color.bwAdaptivePrimary(for: colorScheme)
    }
    
    var body: some View {
        Button(action: {
            BWHaptics.selection()
            // Notify callback (to reset navigation if needed)
            onTabSelected?(index)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Glow effect behind selected icon
                    if isSelected {
                        Circle()
                            .fill(adaptivePrimary.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .blur(radius: 6)
                            .matchedGeometryEffect(id: "glow", in: namespace)
                    }
                    
                    // Icon with animated fill state
                    Image(systemName: isSelected ? filledIcon(for: item.image) : item.image)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? adaptivePrimary : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
                .frame(height: 28)
                
                // Label
                Text(item.title)
                    .font(BWTypography.tabLabel)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? adaptivePrimary : .secondary)
                
                // Indicator dot
                Circle()
                    .fill(adaptivePrimary)
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0)
                    .scaleEffect(isSelected ? 1 : 0.3)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func filledIcon(for name: String) -> String {
        switch name {
        case "house": return "house.fill"
        case "camera": return "camera.fill"
        case "sparkles": return "sparkles"
        case "gear": return "gearshape.fill"
        default: return name
        }
    }
}

// Main tab view after onboarding is complete
struct MainTabView: View {
    @StateObject private var dashboardNavigationState = AppNavigationState()
    @StateObject private var scanNavigationState = AppNavigationState()
    @StateObject private var assistantNavigationState = AppNavigationState()
    @StateObject private var settingsNavigationState = AppNavigationState()
    
    var initialTab: Int = 0
    @State private var selectedTab = 0
    @State private var hasSetInitialTab = false
    
    private let tabItems = [
        (image: "house", title: "Dashboard"),
        (image: "camera", title: "Scan"),
        (image: "sparkles", title: "Assistant"),
        (image: "gear", title: "Settings")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Use conditional view switching instead of TabView to allow navigation back gestures
            Group {
                switch selectedTab {
                case 0:
                    dashboardStack
                case 1:
                    scanStack
                case 2:
                    assistantStack
                case 3:
                    settingsStack
                default:
                    dashboardStack
                }
            }
            
            FloatingTabBar(
                selectedTab: $selectedTab,
                tabItems: tabItems,
                onTabSelected: { tabIndex in
                    // Only reset to root if tapping the SAME tab (standard iOS behavior)
                    // This allows users to navigate back to root by tapping current tab
                    // while preserving navigation stack when switching between tabs
                    if tabIndex == selectedTab {
                        resetNavigationForTab(tabIndex)
                    }
                }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            // Set initial tab only once (e.g., when coming from onboarding "Scan Now")
            if !hasSetInitialTab {
                selectedTab = initialTab
                hasSetInitialTab = true
            }
        }
    }
    
    // MARK: - Tab Stacks
    
    private var dashboardStack: some View {
        NavigationStack(path: $dashboardNavigationState.path) {
            DashboardView()
                .navigationDestination(for: AppScreen.self) { screen in
                    navigationDestination(for: screen, navigationState: dashboardNavigationState)
                }
                .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(dashboardNavigationState)
    }
    
    private var scanStack: some View {
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
    }
    
    private var assistantStack: some View {
        NavigationStack(path: $assistantNavigationState.path) {
            RecipeAIIntroView(onDismiss: {}, showBackButton: false)
                .navigationDestination(for: AppScreen.self) { screen in
                    navigationDestination(for: screen, navigationState: assistantNavigationState)
                }
                .navigationBarHidden(true)
        }
        .environmentObject(assistantNavigationState)
    }
    
    private var settingsStack: some View {
        NavigationStack(path: $settingsNavigationState.path) {
            SettingsView(navigationState: settingsNavigationState)
                .navigationDestination(for: AppScreen.self) { screen in
                    navigationDestination(for: screen, navigationState: settingsNavigationState)
                }
                .navigationBarHidden(true)
        }
        .environmentObject(settingsNavigationState)
    }
    
    // MARK: - Navigation Reset
    
    private func resetNavigationForTab(_ tabIndex: Int) {
        switch tabIndex {
        case 0:
            dashboardNavigationState.navigateToRoot()
        case 1:
            scanNavigationState.navigateToRoot()
        case 2:
            assistantNavigationState.navigateToRoot()
        case 3:
            settingsNavigationState.navigateToRoot()
        default:
            break
        }
    }
    
    @ViewBuilder
    private func navigationDestination(for screen: AppScreen, navigationState: AppNavigationState) -> some View {
        switch screen {
        case .welcome:
            WelcomeScreen {
                navigationState.navigateTo(.pantrySetup)
            }
        
        case .pantrySetup:
            PantrySetupScreen(isOnboarding: false) {
                navigationState.navigateBack()
            }
        
        case .macroGoalsOnboarding:
            MacroGoalsOnboardingScreen(
                onContinue: {
                    navigationState.navigateBack()
                },
                onSkip: {
                    navigationState.navigateBack()
                }
            )
        
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
                navigationState.navigateTo(.recipeSuggestion)
            }
        
        case .userProfile:
            UserProfileScreen {
                navigationState.navigateBack()
            }
        
        case .dailyMacroGoals:
            DailyMacroGoalsScreen()
        
        case .favorites:
            FavoritesScreen()
        
        case .fridgeItems:
            FridgeItemsScreen()
        
        case .pantryItems:
            PantryItemsScreen()
        
        case .chatSettings:
            ChatSettingsScreen {
                navigationState.navigateBack()
            }
        
        case .onboardingCompletion:
            // This screen is only used during onboarding flow, not in main app navigation
            EmptyView()
        }
    }
}

#Preview {
    AppNavigation()
}


