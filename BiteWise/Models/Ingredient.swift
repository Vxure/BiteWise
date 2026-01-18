import Foundation

struct Ingredient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var unit: String = ""
    var isSelected: Bool = true
    /// Staple items (like spices, oils) are not deducted when cooking
    /// Pantry items default to true, fridge items default to false
    var isStaple: Bool = false
}

// Dummy ingredient data
extension Ingredient {
    static var dummyData: [Ingredient] = [
        Ingredient(name: "Chicken"),
        Ingredient(name: "Eggs"),
        Ingredient(name: "Spinach"),
        Ingredient(name: "Cheese"),
        Ingredient(name: "Yogurt"),
        Ingredient(name: "Broccoli")
    ]
    
    /// Pantry staple items - isStaple defaults to true for pantry items
    static var pantryItems: [Ingredient] = [
        Ingredient(name: "Rice", isStaple: true),
        Ingredient(name: "Pasta", isStaple: true),
        Ingredient(name: "Olive Oil", isStaple: true),
        Ingredient(name: "Salt", isStaple: true),
        Ingredient(name: "Pepper", isStaple: true),
        Ingredient(name: "Garlic", isStaple: true),
        Ingredient(name: "Onions", isStaple: true),
        Ingredient(name: "Flour", isStaple: true),
        Ingredient(name: "Sugar", isStaple: true),
        Ingredient(name: "Canned Beans", isStaple: true)
    ]
} 