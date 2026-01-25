import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PantryItemsScreen: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddItemSheet = false
    @State private var showingClearConfirmation = false
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration
    private let headerHeight: CGFloat = 70
    
    // MARK: - Header Animation Calculations
    
    private var scrollProgress: CGFloat {
        min(1, max(0, -scrollOffset / headerHeight))
    }
    
    private var headerOpacity: Double {
        if headerVisible {
            return 1.0
        }
        return Double(1.0 - scrollProgress)
    }
    
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
                    
                    // Spacer for floating header
                    Color.clear
                        .frame(height: headerHeight)
                    
                    if dataManager.pantryItems.isEmpty {
                        // Empty state
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        // Pantry items list
                        pantryItemsList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }
            
            // MARK: - Floating Header Overlay
            VStack(spacing: 0) {
                HStack {
                    // Back button
                    Button(action: {
                        BWHaptics.lightImpact()
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 40, height: 40)
                                .adaptiveShadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                        }
                    }
                    .buttonStyle(.bwPressable)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("My Pantry")
                            .font(BWTypography.cardTitle)
                        
                        if !dataManager.pantryItems.isEmpty {
                            Text("\(dataManager.pantryItems.count) items")
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Menu button
                    if !dataManager.pantryItems.isEmpty {
                        Menu {
                            Button(action: { showingAddItemSheet = true }) {
                                Label("Add Item Manually", systemImage: "plus")
                            }
                            Button(role: .destructive, action: { showingClearConfirmation = true }) {
                                Label("Clear All Items", systemImage: "trash")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 40, height: 40)
                                    .adaptiveShadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                            }
                        }
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background(BWGradients.headerFadeGradient(for: colorScheme))
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
            
            // Expandable Floating Action Button
            ExpandableFAB(
                accentColor: .bwPrimary,
                onScan: {
                    navigationState.navigateTo(.photoUpload)
                },
                onManual: {
                    showingAddItemSheet = true
                }
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddItemSheet) {
            AddPantryItemSheet(isPresented: $showingAddItemSheet)
        }
        .alert("Clear All Items?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    dataManager.pantryItems = []
                    dataManager.savePantryItems()
                }
            }
        } message: {
            Text("This will remove all items from your pantry. This action cannot be undone.")
        }
    }
    
    // MARK: - Scroll Handling
    
    private func handleScrollChange(newOffset: CGFloat) {
        let delta = newOffset - lastScrollOffset
        
        if delta > 2 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        } else if delta < -2 {
            if headerVisible && newOffset < -10 {
                withAnimation(.easeOut(duration: 0.15)) {
                    headerVisible = false
                }
            }
        }
        
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
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.bwPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cabinet.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(Color.bwPrimary.opacity(0.5))
            }
            
            VStack(spacing: 8) {
                Text("Your pantry is empty")
                    .font(BWTypography.cardTitle)
                    .foregroundColor(.primary)
                
                Text("Add staples you always have\nlike rice, pasta, oils, and spices")
                    .font(BWTypography.bodySecondary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                BWHaptics.mediumImpact()
                showingAddItemSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Items")
                        .font(BWTypography.buttonSmall)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.bwPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.bwPressable)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Pantry Items List
    private var pantryItemsList: some View {
        VStack(spacing: 12) {
            ForEach(dataManager.pantryItems) { item in
                PantryItemRow(item: item) {
                    // Delete action
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataManager.removePantryItem(item)
                    }
                }
            }
        }
    }
    
}

// MARK: - Pantry Item Row
struct PantryItemRow: View {
    let item: Ingredient
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteThreshold: CGFloat = -80
    
    // Icon based on item name
    private var itemIcon: String {
        let lowercased = item.name.lowercased()
        if lowercased.contains("oil") || lowercased.contains("olive") {
            return "drop.fill"
        } else if lowercased.contains("salt") || lowercased.contains("pepper") || lowercased.contains("spice") {
            return "leaf.fill"
        } else if lowercased.contains("rice") || lowercased.contains("pasta") || lowercased.contains("grain") {
            return "circle.grid.3x3.fill"
        } else if lowercased.contains("flour") || lowercased.contains("sugar") {
            return "bag.fill"
        } else if lowercased.contains("can") || lowercased.contains("bean") {
            return "cylinder.fill"
        } else if lowercased.contains("garlic") || lowercased.contains("onion") {
            return "leaf.circle.fill"
        } else {
            return "cabinet.fill"
        }
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            HStack {
                Spacer()
                Button(action: {
                    BWHaptics.mediumImpact()
                    onDelete()
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 70)
                        .background(Color.red)
                        .cornerRadius(14)
                }
            }
            .opacity(offset < -20 ? 1 : 0)
            
            // Main content
            HStack(spacing: 14) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: itemIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                }
                
                // Item info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(BWTypography.bodyPrimary)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Pantry staple")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.8))
                }
                
                Spacer()
                
                // Swipe hint
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .adaptiveShadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                            isSwiping = true
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if offset < deleteThreshold {
                                // Show delete button
                                offset = -70
                            } else {
                                offset = 0
                            }
                            isSwiping = false
                        }
                    }
            )
            .onTapGesture {
                // Reset if tapped while showing delete
                if offset != 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                    }
                }
            }
        }
    }
}

// MARK: - Add Pantry Item Sheet
struct AddPantryItemSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var dataManager = DataManager.shared
    @State private var itemName = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Quick add suggestions
    private let suggestions = [
        "Rice", "Pasta", "Olive Oil", "Salt", "Pepper", "Garlic",
        "Onions", "Flour", "Sugar", "Canned Beans", "Soy Sauce",
        "Vinegar", "Honey", "Oats", "Bread", "Butter"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Group {
                    if colorScheme == .dark {
                        Color(.systemBackground)
                    } else {
                        BWGradients.backgroundGradient
                    }
                }
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Add Pantry Item")
                        .font(BWTypography.cardTitle)
                        .padding(.top)
                    
                    // Item name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Item Name")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Rice, Olive Oil", text: $itemName)
                            .font(BWTypography.bodyPrimary)
                            .focused($isInputFocused)
                            .submitLabel(.done)
                            .onSubmit { addItem() }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    
                    // Quick add suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Add")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                        
                        FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                            ForEach(availableSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    BWHaptics.lightImpact()
                                    addQuickItem(suggestion)
                                }) {
                                    Text(suggestion)
                                        .font(BWTypography.captionSmall)
                                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.1))
                                        )
                                }
                                .buttonStyle(.bwPressable)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Add button
                    Button(action: addItem) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Item")
                        }
                        .font(BWTypography.buttonSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: itemName.isEmpty
                                            ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]
                                            : [Color.bwPrimary, Color.bwPrimary.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .disabled(itemName.isEmpty)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(BWTypography.bodyPrimary)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            isInputFocused = true
        }
    }
    
    // Filter out items already in pantry
    private var availableSuggestions: [String] {
        let existingNames = Set(dataManager.pantryItems.map { $0.name.lowercased() })
        return suggestions.filter { !existingNames.contains($0.lowercased()) }
    }
    
    private func addItem() {
        guard !itemName.isEmpty else { return }
        
        // Pantry items are staples by default - they won't be deducted when cooking
        let newItem = Ingredient(
            name: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            isStaple: true
        )
        
        dataManager.addPantryItem(newItem)
        BWHaptics.mediumImpact()
        isPresented = false
    }
    
    private func addQuickItem(_ name: String) {
        // Pantry items are staples by default
        let newItem = Ingredient(name: name, isStaple: true)
        dataManager.addPantryItem(newItem)
        BWHaptics.success()
    }
}

#Preview {
    NavigationStack {
        PantryItemsScreen()
            .environmentObject(AppNavigationState())
    }
}

