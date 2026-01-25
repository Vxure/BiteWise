import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MacroGoalsOnboardingScreen: View {
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var macroGoals = UserProfile.MacroGoals(
        dailyCalories: 2000,
        proteinPercentage: 30,
        carbsPercentage: 40,
        fatsPercentage: 30
    )
    @State private var hasMacroGoals = true
    @State private var isVisible = false
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration (just the progress indicator)
    private let headerHeight: CGFloat = 44
    
    var onContinue: () -> Void
    var onSkip: () -> Void
    
    // MARK: - Header Animation Calculations
    
    /// Progress of scroll (0 = top, 1 = fully scrolled past header height)
    private var scrollProgress: CGFloat {
        min(1, max(0, -scrollOffset / headerHeight))
    }
    
    /// Header opacity based on scroll state
    private var headerOpacity: Double {
        if headerVisible {
            return 1.0
        }
        return Double(1.0 - scrollProgress)
    }
    
    /// Header Y translation based on scroll state
    private var headerTranslateY: CGFloat {
        if headerVisible {
            return 0
        }
        return -headerHeight * scrollProgress
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Invisible anchor for scroll offset tracking
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll")).minY
                                )
                        }
                        .frame(height: 0)
                        
                        // Spacer for the floating progress indicator
                        Color.clear
                            .frame(height: headerHeight)
                        
                        // Header
                        headerSection
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : 20)
                        
                        // Benefits Card
                        benefitsCard
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : 20)
                            .animation(.bwSpring.delay(0.1), value: isVisible)
                        
                        // Macro Editor (embedded, not as sheet)
                        MacroGoalsEditorSheet(
                            macroGoals: $macroGoals,
                            hasMacroGoals: $hasMacroGoals,
                            isSheet: false
                        )
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(.bwSpring.delay(0.2), value: isVisible)
                        
                        // Bottom buttons (inside scroll)
                        VStack(spacing: 8) {
                            GradientButton(
                                icon: "checkmark.circle.fill",
                                text: "Set My Goals",
                                action: saveAndContinue
                            )
                            
                            Button(action: skipMacros) {
                                HStack(spacing: 6) {
                                    Text("Skip for Now")
                                        .font(BWTypography.buttonSmall)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.secondary)
                                .padding(.vertical, 10)
                            }
                        }
                        .padding(.top, -50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    handleScrollChange(newOffset: value)
                }
            }
            
            // MARK: - Floating Progress Indicator Overlay
            VStack(alignment: .leading, spacing: 0) {
                OnboardingProgressView(currentStep: 2, totalSteps: 2)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Gradient background that blends with page background (adaptive for dark mode)
                BWGradients.headerFadeGradient(for: colorScheme)
            )
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
        }
        .navigationTitle("Macro Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .customNavigation()
        .onAppear {
            // Load any existing macro goals
            macroGoals = dataManager.userProfile.macroGoals
            hasMacroGoals = dataManager.userProfile.hasMacroGoals
            
            withAnimation(.bwSpring) {
                isVisible = true
            }
        }
    }
    
    // MARK: - Scroll Handling
    
    /// Handle scroll offset changes and detect scroll direction
    private func handleScrollChange(newOffset: CGFloat) {
        let delta = newOffset - lastScrollOffset
        
        // Detect scroll direction
        if delta > 2 {
            // Scrolling up (content moving down) - show header immediately
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        } else if delta < -2 {
            // Scrolling down (content moving up) - start hiding header
            if headerVisible && newOffset < -10 {
                withAnimation(.easeOut(duration: 0.15)) {
                    headerVisible = false
                }
            }
        }
        
        // Reset to visible when at or near top
        if newOffset >= -5 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        }
        
        scrollOffset = newOffset
        lastScrollOffset = newOffset
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bwProtein.opacity(0.2), Color.bwCarbs.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.bwProtein, Color.bwCarbs],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Set Your Nutrition Goals")
                .font(BWTypography.sectionHeader)
                .multilineTextAlignment(.center)
            
            Text("Help us personalize your recipe recommendations")
                .font(BWTypography.bodySecondary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, -10)
    }
    
    // MARK: - Benefits Card
    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.bwPrimary)
                
                Text("Why set macro goals?")
                    .font(BWTypography.cardTitle)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                benefitRow(
                    icon: "fork.knife",
                    text: "Get recipes tailored to your nutrition needs"
                )
                
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Track daily progress toward your goals"
                )
                
                benefitRow(
                    icon: "heart.fill",
                    text: "Build healthier eating habits over time"
                )
            }
        }
        .bwCardStyle(padding: 18, cornerRadius: 20)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.bwPrimary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.bwPrimary)
            }
            
            Text(text)
                .font(BWTypography.bodySecondary)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func saveAndContinue() {
        BWHaptics.success()
        
        // Save macro goals to user profile
        var profile = dataManager.userProfile
        profile.macroGoals = macroGoals
        profile.hasMacroGoals = true
        dataManager.userProfile = profile
        dataManager.saveUserProfile()
        
        onContinue()
    }
    
    private func skipMacros() {
        BWHaptics.lightImpact()
        
        // Mark as skipped but keep default values
        var profile = dataManager.userProfile
        profile.hasMacroGoals = false
        dataManager.userProfile = profile
        dataManager.saveUserProfile()
        
        onSkip()
    }
}

#Preview {
    NavigationStack {
        MacroGoalsOnboardingScreen(
            onContinue: {},
            onSkip: {}
        )
    }
}
