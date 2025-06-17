import Foundation

struct MacroNutrients: Hashable {
    var protein: Double
    var carbs: Double
    var fats: Double
    var calories: Int
}

struct Recipe: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var description: String
    var imageNamePlaceholder: String
    var ingredients: [String]
    var steps: [String]
    var prepTime: Int // in minutes
    var cookTime: Int // in minutes
    var macros: MacroNutrients
    
    // Implement Hashable manually to use only the id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
}

// Dummy recipe data
extension Recipe {
    static var dummyData: [Recipe] = [
        Recipe(
            title: "Grilled Chicken Salad",
            description: "A healthy protein-packed salad with grilled chicken, fresh vegetables, and a light vinaigrette.",
            imageNamePlaceholder: "chicken_salad",
            ingredients: [
                "2 chicken breasts",
                "1 cup spinach",
                "1/2 cup cherry tomatoes",
                "1/4 cup feta cheese",
                "2 tbsp olive oil",
                "1 tbsp lemon juice",
                "Salt and pepper to taste"
            ],
            steps: [
                "Season chicken breasts with salt and pepper",
                "Grill chicken for 6-7 minutes on each side until cooked through",
                "Chop spinach and tomatoes",
                "Slice cooked chicken",
                "Combine all ingredients in a bowl",
                "Drizzle with olive oil and lemon juice",
                "Toss and serve"
            ],
            prepTime: 10,
            cookTime: 15,
            macros: MacroNutrients(protein: 32, carbs: 8, fats: 14, calories: 320)
        ),
        Recipe(
            title: "Spinach Omelet",
            description: "A quick and easy breakfast packed with nutrients and protein.",
            imageNamePlaceholder: "spinach_omelet",
            ingredients: [
                "3 eggs",
                "1 cup spinach",
                "1/4 cup cheese",
                "1 tbsp butter",
                "Salt and pepper to taste"
            ],
            steps: [
                "Whisk eggs in a bowl with salt and pepper",
                "Melt butter in a pan over medium heat",
                "Add spinach and cook until wilted",
                "Pour eggs over spinach",
                "Sprinkle cheese on top",
                "Cook until eggs are set",
                "Fold omelet in half and serve"
            ],
            prepTime: 5,
            cookTime: 10,
            macros: MacroNutrients(protein: 22, carbs: 3, fats: 18, calories: 280)
        ),
        Recipe(
            title: "Yogurt Parfait",
            description: "A refreshing snack or breakfast option with yogurt, fruit, and granola.",
            imageNamePlaceholder: "yogurt_parfait",
            ingredients: [
                "1 cup Greek yogurt",
                "1/2 cup mixed berries",
                "1/4 cup granola",
                "1 tbsp honey"
            ],
            steps: [
                "Layer Greek yogurt at the bottom of a glass",
                "Add a layer of mixed berries",
                "Add a layer of granola",
                "Repeat layers",
                "Drizzle honey on top",
                "Serve immediately"
            ],
            prepTime: 5,
            cookTime: 0,
            macros: MacroNutrients(protein: 18, carbs: 36, fats: 8, calories: 290)
        )
    ]
} 