import Foundation

struct Ingredient: Identifiable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var unit: String = ""
    var isSelected: Bool = true
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
    
    static var pantryItems: [Ingredient] = [
        Ingredient(name: "Rice"),
        Ingredient(name: "Pasta"),
        Ingredient(name: "Olive Oil"),
        Ingredient(name: "Salt"),
        Ingredient(name: "Pepper"),
        Ingredient(name: "Garlic"),
        Ingredient(name: "Onions"),
        Ingredient(name: "Flour"),
        Ingredient(name: "Sugar"),
        Ingredient(name: "Canned Beans")
    ]
} 