import Foundation

struct Ingredient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var unit: String = ""
    var category: String = "other"
    var isSelected: Bool = true
    /// Staple items (like spices, oils) are not deducted when cooking
    /// Pantry items default to true, fridge items default to false
    var isStaple: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, category, isSelected, isStaple
    }
    
    init(id: UUID = UUID(), name: String, quantity: String = "", unit: String = "",
         category: String = "other", isSelected: Bool = true, isStaple: Bool = false) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isSelected = isSelected
        self.isStaple = isStaple
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity) ?? ""
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "other"
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? true
        isStaple = try container.decodeIfPresent(Bool.self, forKey: .isStaple) ?? false
    }
}

// Dummy ingredient data
extension Ingredient {
    static var dummyData: [Ingredient] = [
        Ingredient(name: "Chicken", category: "protein"),
        Ingredient(name: "Eggs", category: "protein"),
        Ingredient(name: "Spinach", category: "vegetable"),
        Ingredient(name: "Cheese", category: "dairy"),
        Ingredient(name: "Yogurt", category: "dairy"),
        Ingredient(name: "Broccoli", category: "vegetable")
    ]
    
    /// Pantry staple items - isStaple defaults to true for pantry items
    static var pantryItems: [Ingredient] = [
        Ingredient(name: "Rice", category: "grain", isStaple: true),
        Ingredient(name: "Pasta", category: "grain", isStaple: true),
        Ingredient(name: "Olive Oil", category: "condiment", isStaple: true),
        Ingredient(name: "Salt", category: "condiment", isStaple: true),
        Ingredient(name: "Pepper", category: "condiment", isStaple: true),
        Ingredient(name: "Garlic", category: "vegetable", isStaple: true),
        Ingredient(name: "Onions", category: "vegetable", isStaple: true),
        Ingredient(name: "Flour", category: "grain", isStaple: true),
        Ingredient(name: "Sugar", category: "condiment", isStaple: true),
        Ingredient(name: "Canned Beans", category: "protein", isStaple: true)
    ]
    
    /// Common food categories matching FridgeItem categories
    static let categories = [
        "protein", "dairy", "vegetable", "fruit",
        "grain", "condiment", "beverage", "other"
    ]
    
    var categoryDisplayName: String {
        category.capitalized
    }
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "protein": return "fork.knife"
        case "dairy": return "cup.and.saucer.fill"
        case "vegetable": return "leaf.fill"
        case "fruit": return "apple.logo"
        case "grain": return "circle.grid.3x3.fill"
        case "condiment": return "drop.fill"
        case "beverage": return "mug.fill"
        default: return "cabinet.fill"
        }
    }
} 