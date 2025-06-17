import SwiftUI

struct DetectedIngredientsScreen: View {
    @State private var ingredients: [Ingredient] = Ingredient.dummyData
    @State private var newIngredientName: String = ""
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Detected Ingredients")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("We've detected these ingredients in your fridge. Uncheck any that you don't want to use.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Add new ingredient field
            HStack {
                TextField("Add ingredient...", text: $newIngredientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addNewIngredient) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                .disabled(newIngredientName.isEmpty)
            }
            .padding(.horizontal)
            
            // Ingredients list
            List {
                ForEach(ingredients) { ingredient in
                    HStack {
                        Image(systemName: ingredient.isSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(ingredient.isSelected ? .green : .gray)
                        
                        Text(ingredient.name)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleIngredient(ingredient)
                    }
                }
                .onDelete(perform: deleteIngredients)
            }
            .listStyle(PlainListStyle())
            
            // Continue button
            Button(action: onContinue) {
                Text("Find Recipes")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
        }
    }
    
    private func addNewIngredient() {
        guard !newIngredientName.isEmpty else { return }
        let newIngredient = Ingredient(name: newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines))
        ingredients.append(newIngredient)
        newIngredientName = ""
    }
    
    private func toggleIngredient(_ ingredient: Ingredient) {
        if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            ingredients[index].isSelected.toggle()
        }
    }
    
    private func deleteIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
}

#Preview {
    DetectedIngredientsScreen(onContinue: {})
} 