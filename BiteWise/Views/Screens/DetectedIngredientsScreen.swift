import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DetectedIngredientsScreen: View {
    // Ingredients data with selection state - initialized from SessionContext
    @State private var ingredients: [IngredientItem] = []
    @State private var showingAddIngredientSheet = false
    @State private var showingPantrySheet = false
    @State private var newIngredientName = ""
    @ObservedObject private var sessionContext = SessionContext.shared
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Scan merge state
    @State private var showingScanModeSheet = false
    @State private var showingDuplicateSheet = false
    @State private var selectedScanMode: ScanMergeMode = .smartMerge
    @State private var duplicatesToResolve: [DuplicateItem] = []
    @State private var pendingFridgeItems: [FridgeItem] = []
    
    // Header configuration
    private let headerHeight: CGFloat = 70
    
    var onContinue: () -> Void
    
    // Fallback dummy data for demo mode or when no ingredients detected
    private static let dummyIngredients: [IngredientItem] = [
        IngredientItem(name: "Chicken Breast", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Eggs", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Fresh Spinach", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Shredded Cheese", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Milk", isSelected: false, isAIDetected: true),
        IngredientItem(name: "Butter", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Tomatoes", isSelected: false, isAIDetected: true)
    ]
    
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
            // Background gradient
            BWGradients.backgroundGradient
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
                    
                    // Ingredients list
                    VStack(spacing: 10) {
                        ForEach($ingredients) { $ingredient in
                            IngredientCardView(ingredient: $ingredient)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Pantry items row
                    PantryItemsRow(itemCount: dataManager.pantryItems.count) {
                        showingPantrySheet = true
                    }
                    .padding(.horizontal, 20)
                    
                    // Add missing ingredient button
                    Button(action: {
                        showingAddIngredientSheet = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            
                            Text("Add Missing Ingredient")
                                .font(.bwSubheadline())
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .foregroundColor(Color.bwPrimaryCoral)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.bwPrimaryCoral.opacity(0.3), lineWidth: 1.5)
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Get recipe suggestions button
                    GradientButton(
                        icon: "sparkles",
                        text: "Get Recipe Suggestions",
                        action: {
                            // Save selected ingredients to session context
                            let selectedIngredients = ingredients.filter { $0.isSelected }
                            let selectedNames = selectedIngredients.map { $0.name }
                            sessionContext.updateSelectedIngredients(selectedNames)
                            
                            // Also save to fridge items for persistence
                            // Note: saveFridgeItems will call onContinue() after handling merge
                            saveFridgeItems(selectedIngredients)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .padding(.vertical)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            
            // MARK: - Floating Header Overlay
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Your Ingredients")
                    .font(BWTypography.sectionHeader)
                
                Text("Check off what you have and add anything we missed")
                    .font(.bwSubheadline())
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color.bwGradientCream, location: 0),
                        .init(color: Color.bwGradientCream, location: 0.6),
                        .init(color: Color.bwGradientCream.opacity(0.8), location: 0.75),
                        .init(color: Color.bwGradientCream.opacity(0), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
        }
        .navigationTitle("Detected Ingredients")
        .navigationBarTitleDisplayMode(.inline)
        .customNavigation()
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddIngredientSheet) {
            AddIngredientSheet(
                isPresented: $showingAddIngredientSheet,
                ingredientName: $newIngredientName,
                onAdd: addNewIngredient
            )
        }
        .sheet(isPresented: $showingPantrySheet) {
            PantryEditSheet(isPresented: $showingPantrySheet)
        }
        .sheet(isPresented: $showingScanModeSheet) {
            ScanModeSheet(
                existingItemCount: dataManager.fridgeItems.count,
                newItemCount: pendingFridgeItems.count,
                selectedMode: $selectedScanMode,
                onContinue: handleScanModeSelected,
                onCancel: {
                    showingScanModeSheet = false
                }
            )
            .presentationDetents([.height(650), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDuplicateSheet) {
            DuplicateResolutionSheet(
                duplicates: $duplicatesToResolve,
                onApply: handleDuplicatesResolved,
                onCancel: {
                    showingDuplicateSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadIngredientsFromContext()
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
    
    /// Load ingredients from SessionContext or use dummy data as fallback
    private func loadIngredientsFromContext() {
        // Only load if ingredients is empty (first appear)
        guard ingredients.isEmpty else { return }
        
        if sessionContext.detectedIngredients.isEmpty {
            // Use dummy data if no detected ingredients (demo mode or fallback)
            ingredients = Self.dummyIngredients
        } else {
            // Convert DetectedIngredient to IngredientItem
            ingredients = sessionContext.detectedIngredients.map { detected in
                IngredientItem(
                    name: detected.name,
                    isSelected: true,
                    isAIDetected: true
                )
            }
        }
    }
    
    func addNewIngredient() {
        guard !newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let newIngredient = IngredientItem(
            name: newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines),
            isSelected: true,
            isAIDetected: false
        )
        
        ingredients.append(newIngredient)
        newIngredientName = ""
    }
    
    /// Save selected ingredients to fridge storage for persistence
    private func saveFridgeItems(_ items: [IngredientItem]) {
        // Convert IngredientItem to FridgeItem
        let fridgeItems = items.map { item -> FridgeItem in
            // Try to get category from detected ingredients if available
            let detectedIngredient = sessionContext.detectedIngredients.first { $0.name == item.name }
            let category = detectedIngredient?.category ?? "other"
            let quantity = detectedIngredient?.quantity ?? ""
            
            return FridgeItem(
                name: item.name,
                quantity: quantity,
                category: category,
                dateAdded: Date()
            )
        }
        
        // Check if fridge already has items - if so, check default scan behavior
        if dataManager.hasFridgeItems {
            pendingFridgeItems = fridgeItems
            
            // Check user's default scan preference
            let defaultMethod = appSettings.defaultScanMethod
            
            if defaultMethod == .askEveryTime {
                // Show the modal as usual
                showingScanModeSheet = true
            } else {
                // Apply the default method directly without showing modal
                selectedScanMode = defaultMethod
                applyMergeMode(defaultMethod)
            }
        } else {
            // First scan - just add directly
            dataManager.replaceFridgeItems(with: fridgeItems)
            onContinue()
        }
    }
    
    /// Apply the selected merge mode directly (used when skipping modal)
    private func applyMergeMode(_ mode: ScanMergeMode) {
        switch mode {
        case .askEveryTime:
            // Should not happen, but handle gracefully
            showingScanModeSheet = true
            
        case .replace:
            dataManager.replaceFridgeItems(with: pendingFridgeItems)
            onContinue()
            
        case .add:
            dataManager.addFridgeItems(pendingFridgeItems)
            onContinue()
            
        case .smartMerge:
            let duplicates = dataManager.findDuplicates(newItems: pendingFridgeItems)
            if duplicates.isEmpty {
                dataManager.addFridgeItems(pendingFridgeItems)
                onContinue()
            } else {
                duplicatesToResolve = duplicates
                showingDuplicateSheet = true
            }
        }
    }
    
    /// Handle scan mode selection
    private func handleScanModeSelected() {
        showingScanModeSheet = false
        
        switch selectedScanMode {
        case .askEveryTime:
            // This case won't occur since the sheet only shows merge mode options
            // But handle gracefully by showing the sheet again
            showingScanModeSheet = true
            
        case .replace:
            // Replace all existing items with new scan
            dataManager.replaceFridgeItems(with: pendingFridgeItems)
            onContinue()
            
        case .add:
            // Add new items to existing (no duplicate handling)
            dataManager.addFridgeItems(pendingFridgeItems)
            onContinue()
            
        case .smartMerge:
            // Find duplicates and show resolution sheet if any exist
            let duplicates = dataManager.findDuplicates(newItems: pendingFridgeItems)
            
            if duplicates.isEmpty {
                // No duplicates - just add the new items
                dataManager.addFridgeItems(pendingFridgeItems)
                onContinue()
            } else {
                // Show duplicate resolution sheet
                duplicatesToResolve = duplicates
                showingDuplicateSheet = true
            }
        }
    }
    
    /// Handle duplicate resolution completion
    private func handleDuplicatesResolved() {
        showingDuplicateSheet = false
        
        // Apply smart merge with user's resolutions
        dataManager.smartMergeFridgeItems(
            newItems: pendingFridgeItems,
            duplicateResolutions: duplicatesToResolve
        )
        
        onContinue()
    }
}

// Model for ingredient items
struct IngredientItem: Identifiable {
    let id = UUID()
    let name: String
    var isSelected: Bool
    var isAIDetected: Bool
}

// Reusable component for each ingredient card
struct IngredientCardView: View {
    @Binding var ingredient: IngredientItem
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            ZStack {
                Circle()
                    .fill(ingredient.isSelected ? Color.bwAccentGreen : Color.clear)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(ingredient.isSelected ? Color.bwAccentGreen : Color.gray.opacity(0.4), lineWidth: 2)
                    )
                
                if ingredient.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: ingredient.isSelected)
            
            // Ingredient name
            Text(ingredient.name)
                .font(.bwBody())
                .foregroundColor(.primary)
            
            Spacer()
            
            // AI Detected label
            if ingredient.isAIDetected {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                    Text("AI")
                        .font(.bwCaption2())
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.bwPrimaryCoral)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.bwPrimaryCoral.opacity(0.12))
                .cornerRadius(10)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.6))
            }
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            ingredient.isSelected.toggle()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// Sheet for adding a new ingredient
struct AddIngredientSheet: View {
    @Binding var isPresented: Bool
    @Binding var ingredientName: String
    var onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                BWGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Add Missing Ingredient")
                        .font(.bwHeadline())
                        .padding(.top)
                    
                    TextField("Ingredient name", text: $ingredientName)
                        .font(.bwBody())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.8))
                        )
                    
                    GradientButton(
                        icon: "plus.circle.fill",
                        text: "Add Ingredient",
                        action: {
                            onAdd()
                            isPresented = false
                        }
                    )
                    .opacity(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    .disabled(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Spacer()
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.bwBody())
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// Row to navigate to pantry items - styled like ingredient cards
struct PantryItemsRow: View {
    let itemCount: Int
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Pantry icon
                ZStack {
                    Circle()
                        .fill(Color.bwAccentGold.opacity(0.15))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "cabinet.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.bwAccentGold)
                }
                
                // Label with count
                Group {
                    Text("Pantry Items")
                        .foregroundColor(.primary)
                    + (itemCount > 0 ? Text(" (\(itemCount))").foregroundColor(.secondary) : Text(""))
                }
                .font(.bwBody())
                
                Spacer()
                
                // Chevron arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.6))
                }
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// Sheet for editing pantry items
struct PantryEditSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedItems: [String] = []
    @State private var newItemName: String = ""
    
    // Common pantry items that will be displayed as options
    let commonItems = [
        "Salt", "Black Pepper", "Olive Oil", "Garlic",
        "Onions", "Rice", "Pasta", "Flour", "Sugar", "Baking Powder"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                BWGradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edit Pantry Items")
                                .font(.bwTitle2())
                            
                            Text("Items you always have on hand")
                                .font(.bwBody())
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // Add new item field
                        HStack(spacing: 12) {
                            TextField("Add pantry item...", text: $newItemName)
                                .font(.bwBody())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.8))
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
                                                    .fill(isSelected ? Color.bwAccentGreen.opacity(0.2) : Color.white.opacity(0.8))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(isSelected ? Color.bwAccentGreen : Color.gray.opacity(0.2), lineWidth: 1.5)
                                            )
                                            .foregroundColor(isSelected ? Color.bwAccentGreen : .primary)
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
                                                    .foregroundColor(Color.bwAccentGreen.opacity(0.6))
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(
                                            Capsule()
                                                .fill(Color.bwAccentGreen.opacity(0.15))
                                        )
                                        .foregroundColor(Color.bwAccentGreen)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .bwCardStyle()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.bwBody())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .font(.bwBody())
                    .fontWeight(.semibold)
                    .foregroundColor(Color.bwPrimaryCoral)
                }
            }
        }
        .onAppear {
            loadExistingItems()
        }
    }
    
    private func loadExistingItems() {
        selectedItems = dataManager.pantryItems.map { $0.name }
    }
    
    private func saveAndDismiss() {
        let ingredients = selectedItems.map { Ingredient(name: $0) }
        dataManager.pantryItems = ingredients
        dataManager.savePantryItems()
        isPresented = false
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
        DetectedIngredientsScreen(onContinue: {})
    }
}
