import SwiftUI

struct PantrySetupScreen: View {
    @State private var pantryItems: [Ingredient] = Ingredient.pantryItems
    @State private var newItemName: String = ""
    @State private var selectedItems: [String] = ["Salt", "Black Pepper", "Olive Oil", "Garlic"]
    var onContinue: () -> Void
    
    // Common pantry items that will be displayed as options
    let commonItems = [
        "Salt", "Black Pepper", "Olive Oil", "Garlic",
        "Onions", "Rice", "Pasta", "Flour", "Sugar", "Baking Powder"
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Add Your Pantry Staples")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Let us know what you usually have on hand")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Add new item field
                HStack {
                    TextField("Add pantry item...", text: $newItemName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Button(action: addNewItem) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(newItemName.isEmpty)
                }
                
                // Common Items Section
                Text("Common Items:")
                    .font(.headline)
                    .padding(.top)
                
                FlowLayout(items: commonItems, spacing: 8) { item in
                    Button(action: {
                        toggleSelection(item)
                    }) {
                        Text(item)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(Capsule().fill(Color.white))
                            )
                            .foregroundColor(.black)
                    }
                }
                
                // Your Pantry Section
                if !selectedItems.isEmpty {
                    Text("Your Pantry:")
                        .font(.headline)
                        .padding(.top)
                    
                    FlowLayout(items: selectedItems, spacing: 8) { item in
                        HStack(spacing: 4) {
                            Text(item)
                            Button(action: {
                                removeItem(item)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.footnote)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                        .foregroundColor(.black)
                    }
                }
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continue to Photo Upload")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Pantry Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addNewItem() {
        guard !newItemName.isEmpty else { return }
        let itemName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !selectedItems.contains(itemName) {
            selectedItems.append(itemName)
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