import SwiftUI

struct DetectedIngredientsScreen: View {
    // Dummy ingredients data with selection state
    @State private var ingredients: [IngredientItem] = [
        IngredientItem(name: "Chicken Breast", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Eggs", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Fresh Spinach", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Shredded Cheese", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Milk", isSelected: false, isAIDetected: true),
        IngredientItem(name: "Butter", isSelected: true, isAIDetected: true),
        IngredientItem(name: "Tomatoes", isSelected: false, isAIDetected: true)
    ]
    
    @State private var showingAddIngredientSheet = false
    @State private var newIngredientName = ""
    
    var onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Your Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Check off what you have and add anything we missed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Ingredients list
                VStack(spacing: 12) {
                    ForEach($ingredients) { $ingredient in
                        IngredientCardView(ingredient: $ingredient)
                            .onTapGesture {
                                ingredient.isSelected.toggle()
                            }
                    }
                }
                .padding(.horizontal)
                
                // Add missing ingredient button
                Button(action: {
                    showingAddIngredientSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Add Missing Ingredient")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .foregroundColor(.primary)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                
                Spacer()
                
                // Get recipe suggestions button
                Button(action: onContinue) {
                    Text("Get Recipe Suggestions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Detected Ingredients")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddIngredientSheet) {
            AddIngredientSheet(
                isPresented: $showingAddIngredientSheet,
                ingredientName: $newIngredientName,
                onAdd: addNewIngredient
            )
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            ZStack {
                Circle()
                    .fill(ingredient.isSelected ? Color.green : Color.white)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(ingredient.isSelected ? Color.green : Color.gray.opacity(0.5), lineWidth: 2)
                    )
                
                if ingredient.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .onTapGesture {
                ingredient.isSelected.toggle()
            }
            
            // Ingredient name
            Text(ingredient.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // AI Detected label
            if ingredient.isAIDetected {
                Text("AI Detected")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Sheet for adding a new ingredient
struct AddIngredientSheet: View {
    @Binding var isPresented: Bool
    @Binding var ingredientName: String
    var onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Add Missing Ingredient")
                    .font(.headline)
                    .padding(.top)
                
                TextField("Ingredient name", text: $ingredientName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button(action: {
                    onAdd()
                    isPresented = false
                }) {
                    Text("Add Ingredient")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        DetectedIngredientsScreen(onContinue: {})
    }
} 