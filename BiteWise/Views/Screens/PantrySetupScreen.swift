import SwiftUI

struct PantrySetupScreen: View {
    @State private var pantryItems: [Ingredient] = Ingredient.pantryItems
    @State private var newItemName: String = ""
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Pantry Setup")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Select common ingredients you usually have in your pantry")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Add new item field
            HStack {
                TextField("Add new item...", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                .disabled(newItemName.isEmpty)
            }
            .padding(.horizontal)
            
            // Pantry items list
            List {
                ForEach(pantryItems) { item in
                    HStack {
                        Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(item.isSelected ? .green : .gray)
                        
                        Text(item.name)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleItem(item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(PlainListStyle())
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
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
    
    private func addNewItem() {
        guard !newItemName.isEmpty else { return }
        let newItem = Ingredient(name: newItemName.trimmingCharacters(in: .whitespacesAndNewlines))
        pantryItems.append(newItem)
        newItemName = ""
    }
    
    private func toggleItem(_ item: Ingredient) {
        if let index = pantryItems.firstIndex(where: { $0.id == item.id }) {
            pantryItems[index].isSelected.toggle()
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        pantryItems.remove(atOffsets: offsets)
    }
}

#Preview {
    PantrySetupScreen(onContinue: {})
} 