import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PantrySetupScreen: View {
    @State private var newItemName: String = ""
    @State private var selectedItems: [String] = []
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration (just the progress indicator)
    private let headerHeight: CGFloat = 44
    
    /// Whether this is during onboarding (true) or from settings (false)
    var isOnboarding: Bool = true
    var onContinue: () -> Void
    
    // Common pantry items that will be displayed as options
    let commonItems = [
        "Salt", "Black Pepper", "Olive Oil", "Garlic",
        "Onions", "Rice", "Pasta", "Flour", "Sugar", "Baking Powder"
    ]
    
    /// Button text changes based on context
    private var buttonText: String {
        isOnboarding ? "Get Started" : "Save"
    }
    
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
            
            // Main scroll content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Invisible anchor for scroll offset tracking
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                    }
                    .frame(height: 0)
                    
                    // Spacer for the floating progress indicator (onboarding only)
                    if isOnboarding {
                        Color.clear
                            .frame(height: headerHeight)
                    }
                    
                    // Header content (scrolls with content)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Your Pantry Staples")
                            .font(.bwTitle())
                        
                        Text("Let us know what you usually have on hand")
                            .font(.bwBody())
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, isOnboarding ? 0 : 16)
                    
                    // Explanation card (onboarding only)
                    if isOnboarding {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.bwAccentGold)
                            
                            Text("We'll assume you have these items when suggesting recipes, so you won't need to add them every time.")
                                .font(.bwCaption())
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bwAccentGold.opacity(0.1))
                        )
                    }
                    
                    // Add new item field
                    HStack(spacing: 12) {
                        TextField("Add pantry item...", text: $newItemName)
                            .font(.bwBody())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        
                        Button(action: addNewItem) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color.bwPrimaryCoral, Color.bwPrimaryOrange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: Color.bwPrimaryCoral.opacity(0.3), radius: 6, y: 3)
                        }
                        .disabled(newItemName.isEmpty)
                        .opacity(newItemName.isEmpty ? 0.6 : 1.0)
                    }
                    
                    // Common Items Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common Items")
                            .font(.bwHeadline())
                        
                        FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                            ForEach(commonItems, id: \.self) { item in
                                let isSelected = selectedItems.contains(item)
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        toggleSelection(item)
                                    }
                                }) {
                                    Text(item)
                                        .font(.bwSubheadline())
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 18)
                                        .background(
                                            Capsule()
                                                .fill(isSelected 
                                                    ? Color.bwAdaptiveAccentGreen(for: colorScheme).opacity(colorScheme == .dark ? 0.25 : 0.2) 
                                                    : Color(.tertiarySystemBackground))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(isSelected 
                                                    ? Color.bwAdaptiveAccentGreen(for: colorScheme) 
                                                    : Color.secondary.opacity(0.2), lineWidth: 1.5)
                                        )
                                        .foregroundColor(isSelected ? Color.bwAdaptiveAccentGreen(for: colorScheme) : .primary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bwCardStyle()
                    
                    // Your Pantry Section
                    if !selectedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Your Pantry")
                                    .font(.bwHeadline())
                                
                                Spacer()
                                
                                Text("\(selectedItems.count) items")
                                    .font(.bwCaption())
                                    .foregroundColor(.secondary)
                            }
                            
                            FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                                ForEach(selectedItems, id: \.self) { item in
                                    HStack(spacing: 6) {
                                        Text(item)
                                            .font(.bwSubheadline())
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                removeItem(item)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color.bwAdaptiveAccentGreen(for: colorScheme).opacity(0.6))
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Capsule()
                                            .fill(Color.bwAdaptiveAccentGreen(for: colorScheme).opacity(colorScheme == .dark ? 0.2 : 0.15))
                                    )
                                    .foregroundColor(Color.bwAdaptiveAccentGreen(for: colorScheme))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .bwCardStyle()
                    }
                    
                    // Continue/Save button
                    VStack(spacing: 8) {
                        GradientButton(
                            icon: isOnboarding ? "arrow.right" : "checkmark",
                            text: buttonText,
                            action: saveAndContinue
                        )
                        
                        // Skip button (only during onboarding)
                        if isOnboarding {
                            Button(action: skipAndContinue) {
                                HStack(spacing: 6) {
                                    Text("Skip for Now")
                                        .font(.bwSubheadline())
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.secondary)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 1)
            }
            
            // MARK: - Floating Progress Indicator Overlay (onboarding only)
            if isOnboarding {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingProgressView(currentStep: 1, totalSteps: 2)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BWGradients.headerFadeGradient(for: colorScheme))
                .offset(y: headerTranslateY)
                .opacity(headerOpacity)
                .animation(.easeOut(duration: 0.2), value: headerVisible)
            }
        }
        .navigationTitle("Pantry Setup")
        .navigationBarTitleDisplayMode(.inline)
        .customNavigation()
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadExistingPantryItems()
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
    
    /// Load existing pantry items from DataManager
    private func loadExistingPantryItems() {
        let existingItems = dataManager.pantryItems.map { $0.name }
        if !existingItems.isEmpty {
            selectedItems = existingItems
        } else if isOnboarding {
            // Default selection for onboarding only
            selectedItems = ["Salt", "Black Pepper", "Olive Oil", "Garlic"]
        }
    }
    
    /// Save pantry items to DataManager and continue
    private func saveAndContinue() {
        // Convert selected items to Ingredient objects - pantry items are staples by default
        let ingredients = selectedItems.map { Ingredient(name: $0, isStaple: true) }
        dataManager.pantryItems = ingredients
        dataManager.savePantryItems()
        onContinue()
    }
    
    /// Skip pantry setup without saving (onboarding only)
    private func skipAndContinue() {
        // Continue without saving any pantry items
        onContinue()
    }
    
    private func addNewItem() {
        guard !newItemName.isEmpty else { return }
        let itemName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !selectedItems.contains(itemName) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedItems.append(itemName)
            }
        }
        newItemName = ""
    }
    
    private func toggleSelection(_ item: String) {
        if selectedItems.contains(item) {
            selectedItems.removeAll { $0 == item }
        } else {
            selectedItems.append(item)
        }
    }
    
    private func removeItem(_ item: String) {
        selectedItems.removeAll { $0 == item }
    }
}

#Preview {
    NavigationStack {
        PantrySetupScreen(onContinue: {})
    }
}
