import SwiftUI

/// Sheet for resolving duplicate items during smart merge
struct DuplicateResolutionSheet: View {
    @Binding var duplicates: [DuplicateItem]
    @Environment(\.colorScheme) var colorScheme
    var onApply: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.bwAccent, Color.bwAccentOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.bwAccent.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Resolve Duplicates")
                    .font(.bwTitle2())
                
                Text("We found \(duplicates.count) item\(duplicates.count == 1 ? "" : "s") that already exist in your fridge.")
                    .font(.bwSubheadline())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            // Duplicates list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach($duplicates) { $duplicate in
                        DuplicateItemRow(duplicate: $duplicate)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 400)
            
            // Action buttons
            VStack(spacing: 12) {
                GradientButton(
                    icon: "checkmark.circle.fill",
                    text: "Apply Changes",
                    action: {
                        BWHaptics.success()
                        onApply()
                    }
                )
                
                Button(action: {
                    BWHaptics.lightImpact()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.bwHeadline())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bwPressable)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            (colorScheme == .dark ? Color(.systemBackground) : Color.bwBackgroundCream)
                .ignoresSafeArea()
        )
    }
}

/// Row for resolving a single duplicate item
struct DuplicateItemRow: View {
    @Binding var duplicate: DuplicateItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item name header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: duplicate.existingItem.categoryIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                }
                
                Text(duplicate.existingItem.name)
                    .font(.bwHeadline())
                
                Spacer()
            }
            
            // Quantity comparison
            HStack(spacing: 16) {
                // Existing quantity
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                    
                    Text(duplicate.existingItem.quantity.isEmpty ? "No quantity" : duplicate.existingItem.quantity)
                        .font(.bwBody())
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                // New quantity
                VStack(alignment: .trailing, spacing: 4) {
                    Text("New Scan")
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                    
                    Text(duplicate.newItem.quantity.isEmpty ? "No quantity" : duplicate.newItem.quantity)
                        .font(.bwBody())
                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            
            // Resolution options
            HStack(spacing: 8) {
                ForEach(DuplicateItem.DuplicateResolution.allCases, id: \.self) { resolution in
                    ResolutionOptionButton(
                        resolution: resolution,
                        isSelected: duplicate.resolution == resolution,
                        canCombine: canCombineQuantities,
                        onSelect: {
                            BWHaptics.selection()
                            withAnimation(.bwSnappy) {
                                duplicate.resolution = resolution
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    /// Check if quantities can be combined (both have numeric values)
    private var canCombineQuantities: Bool {
        let existingHasNumber = duplicate.existingItem.quantity.contains(where: { $0.isNumber })
        let newHasNumber = duplicate.newItem.quantity.contains(where: { $0.isNumber })
        return existingHasNumber && newHasNumber
    }
}

/// Button for selecting a resolution option
struct ResolutionOptionButton: View {
    let resolution: DuplicateItem.DuplicateResolution
    let isSelected: Bool
    let canCombine: Bool
    var onSelect: () -> Void
    
    private var isDisabled: Bool {
        resolution == .combine && !canCombine
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(resolution.rawValue)
                    .font(.bwCaption())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? .white : (isDisabled ? .gray.opacity(0.5) : Color.bwPrimary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.bwPrimary : Color.bwPrimary.opacity(0.1))
            )
        }
        .buttonStyle(.bwPressable)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
    
    private var iconName: String {
        switch resolution {
        case .keepExisting: return "arrow.uturn.backward"
        case .replace: return "arrow.right.arrow.left"
        case .combine: return "plus.circle"
        }
    }
}

#Preview {
    DuplicateResolutionSheet(
        duplicates: .constant([
            DuplicateItem(
                existingItem: FridgeItem(name: "Eggs", quantity: "2", category: "protein"),
                newItem: FridgeItem(name: "Eggs", quantity: "6", category: "protein")
            ),
            DuplicateItem(
                existingItem: FridgeItem(name: "Milk", quantity: "1 carton", category: "dairy"),
                newItem: FridgeItem(name: "Milk", quantity: "1 carton", category: "dairy")
            ),
            DuplicateItem(
                existingItem: FridgeItem(name: "Cheese", quantity: "", category: "dairy"),
                newItem: FridgeItem(name: "Cheese", quantity: "200g", category: "dairy")
            )
        ]),
        onApply: {},
        onCancel: {}
    )
}

