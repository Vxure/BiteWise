import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FridgeItemsScreen: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddItemSheet = false
    @State private var itemToDelete: FridgeItem?
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
                    
                    // Auto-expire info banner (if enabled)
                    if appSettings.fridgeAutoExpireEnabled {
                        autoExpireBanner
                    }
                    
                    if dataManager.fridgeItems.isEmpty {
                        // Empty state
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        // Fridge items list
                        fridgeItemsList
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
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.bwAccentBlue)
                        }
                    }
                    .buttonStyle(.bwPressable)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("My Fridge")
                            .font(BWTypography.cardTitle)
                        
                        if !dataManager.fridgeItems.isEmpty {
                            Text("\(dataManager.fridgeItems.count) items")
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                        } else if let timeAgo = dataManager.lastFridgeScanTimeAgo {
                            Text("Scanned \(timeAgo)")
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Menu button
                    if !dataManager.fridgeItems.isEmpty {
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
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.bwAccentBlue)
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
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    scanMoreButton
                        .allowsHitTesting(true)
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                }
            }
            .allowsHitTesting(false)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddItemSheet) {
            AddFridgeItemSheet(isPresented: $showingAddItemSheet)
        }
        .alert("Clear All Items?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    dataManager.clearAllFridgeItems()
                }
            }
        } message: {
            Text("This will remove all items from your fridge. This action cannot be undone.")
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
    
    // MARK: - Auto-Expire Banner
    private var autoExpireBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.bwAccentGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto-expire enabled")
                    .font(BWTypography.captionSmall)
                    .fontWeight(.medium)
                
                Text("Items older than \(appSettings.fridgeAutoExpireDays) days are automatically removed")
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bwAccentGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.bwAccentGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.bwAccentBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "refrigerator")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(Color.bwAccentBlue.opacity(0.5))
            }
            
            VStack(spacing: 8) {
                Text("Your fridge is empty")
                    .font(BWTypography.cardTitle)
                    .foregroundColor(.primary)
                
                Text("Scan your fridge to add ingredients\nand get recipe suggestions")
                    .font(BWTypography.bodySecondary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                BWHaptics.mediumImpact()
                navigationState.navigateTo(.photoUpload)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Scan Fridge")
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
                                colors: [Color.bwAccentBlue, Color.bwAccentBlue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.bwAccentBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.bwPressable)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Fridge Items List
    private var fridgeItemsList: some View {
        VStack(spacing: 12) {
            ForEach(dataManager.fridgeItemsSortedByDate) { item in
                FridgeItemRow(item: item) {
                    // Delete action
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataManager.removeFridgeItem(item)
                    }
                }
            }
        }
    }
    
    // MARK: - Scan More Button
    private var scanMoreButton: some View {
        Button(action: {
            BWHaptics.mediumImpact()
            navigationState.navigateTo(.photoUpload)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Scan")
                    .font(BWTypography.buttonSmall)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.bwAccentBlue, Color.bwAccentBlue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.bwAccentBlue.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.bwPressable)
    }
}

// MARK: - Fridge Item Row
struct FridgeItemRow: View {
    let item: FridgeItem
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteThreshold: CGFloat = -80
    
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
                        .fill(Color.bwAccentBlue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: item.categoryIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.bwAccentBlue)
                }
                
                // Item info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(BWTypography.bodyPrimary)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        if !item.quantity.isEmpty {
                            Text(item.quantity)
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                        }
                        
                        // Time badge
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(item.timeAgoString)
                                .font(BWTypography.captionSmall)
                        }
                        .foregroundColor(Color.bwAccentBlue.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Swipe hint
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
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

// MARK: - Add Fridge Item Sheet
struct AddFridgeItemSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var dataManager = DataManager.shared
    @State private var itemName = ""
    @State private var quantity = ""
    @State private var selectedCategory = "other"
    
    var body: some View {
        NavigationStack {
            ZStack {
                BWGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Add Fridge Item")
                        .font(BWTypography.cardTitle)
                        .padding(.top)
                    
                    // Item name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Item Name")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Chicken Breast", text: $itemName)
                            .font(BWTypography.bodyPrimary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    }
                    
                    // Quantity (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quantity (optional)")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., 2 lbs", text: $quantity)
                            .font(BWTypography.bodyPrimary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    }
                    
                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FridgeItem.categories, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
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
                                            : [Color.bwAccentBlue, Color.bwAccentBlue.opacity(0.8)],
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
    }
    
    private func addItem() {
        guard !itemName.isEmpty else { return }
        
        let newItem = FridgeItem(
            name: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory
        )
        
        dataManager.addFridgeItem(newItem)
        BWHaptics.mediumImpact()
        isPresented = false
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category.capitalized)
                .font(BWTypography.captionSmall)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.bwAccentBlue : Color.white)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        FridgeItemsScreen()
            .environmentObject(AppNavigationState())
    }
}

