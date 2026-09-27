import SwiftUI
import Combine

// Navigation path used to keep track of screen stack
enum AppScreen: Hashable {
    case welcome
    case pantrySetup
    case macroGoalsOnboarding
    case signup
    case onboardingCompletion
    case photoUpload
    case detectedIngredients
    case recipeSuggestion
    case recipeDetail(Recipe)
    case recipeAIAssistant
    case feedback
    case userProfile
    case nutritionPreferences
    case dailyMacroGoals
    case favorites
    case fridgeItems
    case pantryItems
    case chatSettings
    
    // Auth screens
    case authWelcome
    case authLogin
    case authRegister
    case authForgotPassword
    case authVerifyEmail
    case authMagicLinkSent
    
    // New onboarding screens
    case onboardingIntroduction
    case onboardingName
    case onboardingAge
    case onboardingDietary
    case onboardingAllergies
    case onboardingExperience
    case onboardingCookingTime
    case onboardingTastePreferences
    case onboardingMacroTracking
    case onboardingCongratulations
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

class TabSelectionState: ObservableObject {
    @Published var selectedTab: Int = 0
    
    func switchToTab(_ index: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            selectedTab = index
        }
    }
}

/// Main navigation container for Taberoux app.
///
/// ## Authentication Flow
///
/// Users must authenticate (sign up or sign in) before accessing the app.
/// The onboarding flow requires authentication first, then walks users through
/// pantry setup and macro goals before entering the main app.
///
struct AppNavigation: View {
    @StateObject private var navigationState = AppNavigationState()
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var guestModeService = GuestModeService.shared
    @EnvironmentObject private var deepLinkManager: DeepLinkStateManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var initialTabAfterOnboarding: Int = 0
    @State private var isCheckingAuth: Bool = true
    
    // MARK: - Password Reset Security Timeout
    /// Timestamp when password reset screen was shown
    @State private var passwordResetStartTime: Date?
    /// Security timeout for password reset (5 minutes)
    private let passwordResetTimeout: TimeInterval = 300
    
    private var canAccessMainApp: Bool {
        authService.isAuthenticated || guestModeService.isGuestMode
    }
    
    /// Check if we have a pending password recovery that needs to show the reset screen
    private var showPasswordResetOverlay: Bool {
        if case .recoveryReady = deepLinkManager.pendingResult {
            return true
        }
        return false
    }
    
    /// Get the email for password reset if available
    private var passwordResetEmail: String {
        if case .recoveryReady(let email) = deepLinkManager.pendingResult {
            return email
        }
        return ""
    }
    
    var body: some View {
        ZStack {
            // Main content based on auth state
            Group {
                if isCheckingAuth {
                    AuthLoadingView()
                } else if !hasCompletedOnboarding {
                    OnboardingFlow(
                        onComplete: {
                            initialTabAfterOnboarding = 0
                            hasCompletedOnboarding = true
                        },
                        onCompleteWithScan: {
                            initialTabAfterOnboarding = 1
                            hasCompletedOnboarding = true
                        },
                        onDevSkip: {
                            guestModeService.enableGuestMode()
                            initialTabAfterOnboarding = 0
                            hasCompletedOnboarding = true
                        }
                    )
                    .transition(.opacity)
                } else if !canAccessMainApp {
                    ReturningUserAuthFlow()
                        .transition(.opacity)
                } else {
                    MainTabView(initialTab: initialTabAfterOnboarding)
                        .environmentObject(navigationState)
                        .transition(.opacity)
                }
            }
            
            // Password reset overlay - shown on top of any screen when recovery link is clicked
            if showPasswordResetOverlay {
                PasswordResetScreen(
                    email: passwordResetEmail,
                    onComplete: {
                        // Password was reset successfully
                        deepLinkManager.clearPendingResult()
                        // User will be signed out by AuthService, navigation will update
                    },
                    onCancel: {
                        // User cancelled - clear the pending result
                        deepLinkManager.clearPendingResult()
                    }
                )
                .transition(.opacity)
                .zIndex(100) // Ensure it's above other content
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: isCheckingAuth)
        .animation(.easeInOut(duration: 0.3), value: showPasswordResetOverlay)
        .task {
            // Check for existing session on app launch
            await checkAuthentication()
        }
        // Track when password reset screen is shown for security timeout
        .onChange(of: showPasswordResetOverlay) { _, isShowing in
            if isShowing {
                passwordResetStartTime = Date()
            } else {
                passwordResetStartTime = nil
            }
        }
        // Security: Auto-dismiss password reset after timeout (5 minutes)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            guard let startTime = passwordResetStartTime,
                  showPasswordResetOverlay else { return }
            
            if Date().timeIntervalSince(startTime) > passwordResetTimeout {
                // Security timeout - clear the pending result
                deepLinkManager.clearPendingResult()
                passwordResetStartTime = nil
            }
        }
    }
    
    private func checkAuthentication() async {
        // Small delay for splash effect
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // DEBUG: Uncomment the lines below to reset onboarding for testing
        // hasCompletedOnboarding = false
        // guestModeService.resetGuestMode()
        
        // AuthService automatically updates isAuthenticated via auth state listener
        // We just need to wait for it to initialize
        isCheckingAuth = false
    }
}

// MARK: - Auth Loading View

struct AuthLoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    LinearGradient(
                        colors: [
                            Color.bwSurface,
                            Color.bwBackgroundPeach,
                            Color.bwSurface.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated logo
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.bwPrimary.opacity(0.15),
                                    Color.bwPrimary.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(pulseScale)
                    
                    // Logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.bwPrimary.opacity(0.2), radius: 25, x: 0, y: 12)
                    
                    // Leaf icon
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 55)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name
                Text("Taberoux")
                    .font(BWTypography.displayMedium)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.bwPrimary, Color.bwSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            // Logo entrance animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// Auth flow for returning users (completed onboarding, logged out).
// AuthLoginScreen as root -- no welcome. Navigation auto-resolves when
// authService.isAuthenticated becomes true (canAccessMainApp flips in AppNavigation).
struct ReturningUserAuthFlow: View {
    @StateObject private var navigationState = AppNavigationState()
    @StateObject private var authViewModel = AuthViewModel(initialState: .login)
    @ObservedObject private var authService = AuthService.shared
    @EnvironmentObject private var deepLinkManager: DeepLinkStateManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var didRegisterNewAccount = false
    
    var body: some View {
        NavigationStack(path: $navigationState.path) {
            AuthLoginScreen(
                viewModel: authViewModel,
                onSignUp: { navigationState.navigateTo(.authRegister) },
                onForgotPassword: { navigationState.navigateTo(.authForgotPassword) },
                onMagicLinkSent: { navigationState.navigateTo(.authMagicLinkSent) }
            )
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .authRegister:
                    AuthRegisterScreen(
                        viewModel: authViewModel,
                        onSignIn: { navigationState.navigateBack() },
                        onSuccess: {
                            didRegisterNewAccount = true
                            navigationState.navigateTo(.authVerifyEmail)
                        }
                    )
                
                case .authForgotPassword:
                    AuthForgotPasswordScreen(
                        initialEmail: authViewModel.email,
                        onBackToLogin: { navigationState.navigateBack() }
                    )
                
                case .authVerifyEmail:
                    AuthVerifyEmailScreen(
                        email: authViewModel.email,
                        viewModel: authViewModel,
                        onBackToLogin: { navigationState.navigateToRoot() }
                    )
                
                case .authMagicLinkSent:
                    AuthMagicLinkSentScreen(
                        email: authViewModel.email,
                        viewModel: authViewModel,
                        onBackToLogin: {
                            authViewModel.backToLogin()
                            navigationState.navigateToRoot()
                        }
                    )
                
                default:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(navigationState)
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated, didRegisterNewAccount {
                hasCompletedOnboarding = false
            }
        }
        .onChange(of: deepLinkManager.showSuccess) { _, showSuccess in
            if showSuccess, let message = deepLinkManager.successMessage, message.contains("Email verified") {
                if case .awaitingEmailVerification(let email) = authViewModel.authState {
                    authViewModel.transitionToVerifiedAwaitingLogin(email: email)
                }
                navigationState.navigateToRoot()
            }
        }
    }
}

// Welcome → Auth (new screens) → Onboarding → Pantry/Macro/Completion → Congratulations → Main App
struct OnboardingFlow: View {
    @StateObject private var navigationState = AppNavigationState()
    @StateObject private var authViewModel = AuthViewModel(initialState: .signup)
    @ObservedObject private var authService = AuthService.shared
    @EnvironmentObject private var deepLinkManager: DeepLinkStateManager
    @State private var hasStartedOnboarding = false
    var onComplete: () -> Void
    var onCompleteWithScan: (() -> Void)?
    var onDevSkip: (() -> Void)?
    
    var body: some View {
        NavigationStack(path: $navigationState.path) {
            WelcomeScreen {
                navigationState.navigateTo(.authWelcome)
            }
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .welcome:
                    WelcomeScreen {
                        navigationState.navigateTo(.authWelcome)
                    }
                
                case .authWelcome:
                    AuthWelcomeScreen(
                        onLogin: { navigationState.navigateTo(.authLogin) },
                        onRegister: { navigationState.navigateTo(.authRegister) },
                        onDevSkip: onDevSkip
                    )
                
                case .authLogin:
                    AuthLoginScreen(
                        viewModel: authViewModel,
                        onSignUp: { navigationState.navigateTo(.authRegister) },
                        onForgotPassword: { navigationState.navigateTo(.authForgotPassword) },
                        onMagicLinkSent: { navigationState.navigateTo(.authMagicLinkSent) }
                    )
                
                case .authRegister:
                    AuthRegisterScreen(
                        viewModel: authViewModel,
                        onSignIn: { navigationState.navigateTo(.authLogin) },
                        onSuccess: { navigationState.navigateTo(.authVerifyEmail) }
                    )
                
                case .authForgotPassword:
                    AuthForgotPasswordScreen(
                        initialEmail: authViewModel.email,
                        onBackToLogin: { navigationState.navigateBack() }
                    )
                
                case .authVerifyEmail:
                    AuthVerifyEmailScreen(
                        email: authViewModel.email,
                        viewModel: authViewModel,
                        onBackToLogin: {
                            navigationState.navigateToRoot()
                            navigationState.navigateTo(.authLogin)
                        }
                    )
                
                case .authMagicLinkSent:
                    AuthMagicLinkSentScreen(
                        email: authViewModel.email,
                        viewModel: authViewModel,
                        onBackToLogin: {
                            authViewModel.backToLogin()
                            navigationState.navigateBack()
                        }
                    )
                
                case .onboardingIntroduction:
                    OnboardingIntroductionScreen {
                        navigationState.navigateTo(.onboardingName)
                    }
                
                case .onboardingName:
                    OnboardingNameScreen(
                        onContinue: { navigationState.navigateTo(.onboardingAge) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingAge:
                    OnboardingAgeScreen(
                        onContinue: { navigationState.navigateTo(.onboardingDietary) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingDietary:
                    OnboardingDietaryScreen(
                        onContinue: { navigationState.navigateTo(.onboardingAllergies) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingAllergies:
                    OnboardingAllergiesScreen(
                        onContinue: { navigationState.navigateTo(.onboardingExperience) },
                        onSkip: { navigationState.navigateTo(.onboardingExperience) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingExperience:
                    OnboardingExperienceScreen(
                        onContinue: { navigationState.navigateTo(.onboardingCookingTime) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingCookingTime:
                    OnboardingCookingTimeScreen(
                        onContinue: { navigationState.navigateTo(.onboardingTastePreferences) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingTastePreferences:
                    OnboardingTastePreferencesScreen(
                        onContinue: { navigationState.navigateTo(.onboardingMacroTracking) },
                        onSkip: { navigationState.navigateTo(.onboardingMacroTracking) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .onboardingMacroTracking:
                    OnboardingMacroTrackingScreen(
                        onContinue: { navigationState.navigateTo(.pantrySetup) },
                        onSkip: { navigationState.navigateTo(.pantrySetup) },
                        onBack: { navigationState.navigateBack() }
                    )
                
                case .pantrySetup:
                    PantrySetupScreen {
                        navigationState.navigateTo(.macroGoalsOnboarding)
                    }
                
                case .macroGoalsOnboarding:
                    MacroGoalsOnboardingScreen(
                        onContinue: {
                            navigationState.navigateTo(.onboardingCompletion)
                        },
                        onSkip: {
                            navigationState.navigateTo(.onboardingCompletion)
                        }
                    )
                
                case .onboardingCompletion:
                    OnboardingCompletionScreen(
                        onComplete: {
                            navigationState.navigateTo(.onboardingCongratulations)
                        },
                        onScanNow: {
                            navigationState.navigateTo(.onboardingCongratulations)
                        }
                    )
                
                case .onboardingCongratulations:
                    OnboardingCongratulationsScreen {
                        onComplete()
                    }
                
                default:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(navigationState)
        }
        .task {
            if authService.isAuthenticated, !hasStartedOnboarding {
                handlePostAuth()
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated, !hasStartedOnboarding {
                handlePostAuth()
            }
        }
        .onChange(of: deepLinkManager.showSuccess) { _, showSuccess in
            if showSuccess, !hasStartedOnboarding,
               let message = deepLinkManager.successMessage, message.contains("Email verified") {
                if case .awaitingEmailVerification(let email) = authViewModel.authState {
                    authViewModel.transitionToVerifiedAwaitingLogin(email: email)
                }
                navigationState.navigateToRoot()
                navigationState.navigateTo(.authLogin)
            }
        }
    }
    
    private func handlePostAuth() {
        guard !hasStartedOnboarding else { return }
        hasStartedOnboarding = true
        
        if let user = authService.currentUser {
            var profile = DataManager.shared.userProfile
            if let email = user.email, profile.email.isEmpty {
                profile.email = email
            }
            if profile.name.isEmpty, let metadata = user.userMetadata["name"] {
                if case .string(let name) = metadata {
                    profile.name = name
                }
            }
            DataManager.shared.userProfile = profile
            DataManager.shared.saveUserProfile()
        }
        
        BWHaptics.success()
        
        if isLoginAction() {
            withAnimation(.easeInOut) {
                onComplete()
            }
        } else {
            navigationState.navigateTo(.onboardingIntroduction)
        }
    }
    
    private func isLoginAction() -> Bool {
        switch authViewModel.authState {
        case .login, .awaitingMagicLink, .verifiedAwaitingLogin, .passwordResetPending:
            return true
        case .awaitingEmailVerification:
            return false
        case .signup:
            if case .magicLinkAuthenticated = deepLinkManager.lastResult {
                return true
            }
            return false
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
    @StateObject private var tabSelection = TabSelectionState()
    
    var initialTab: Int = 0
    @State private var hasSetInitialTab = false
    
    private let tabItems = [
        (image: "house", title: "Dashboard"),
        (image: "camera", title: "Scan"),
        (image: "sparkles", title: "Assistant"),
        (image: "gear", title: "Settings")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tabSelection.selectedTab {
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
                selectedTab: $tabSelection.selectedTab,
                tabItems: tabItems,
                onTabSelected: { tabIndex in
                    if tabIndex == tabSelection.selectedTab {
                        resetNavigationForTab(tabIndex)
                    }
                }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            if !hasSetInitialTab {
                tabSelection.selectedTab = initialTab
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
        .environmentObject(tabSelection)
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
        
        case .nutritionPreferences:
            NutritionPreferencesScreen {
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
        
        case .signup, .onboardingCompletion,
             .authWelcome, .authLogin, .authRegister, .authForgotPassword, .authVerifyEmail, .authMagicLinkSent,
             .onboardingIntroduction, .onboardingName, .onboardingAge, .onboardingDietary,
             .onboardingAllergies, .onboardingExperience, .onboardingCookingTime,
             .onboardingTastePreferences, .onboardingMacroTracking, .onboardingCongratulations:
            EmptyView()
        }
    }
}

#Preview {
    AppNavigation()
}


