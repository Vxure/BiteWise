import Foundation

struct MacroNutrients: Hashable, Codable {
    var protein: Double
    var carbs: Double
    var fats: Double
    var calories: Int
}

struct Recipe: Identifiable, Hashable, Codable {
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

// Dummy recipe data with stable UUIDs (so favorites persist across app launches)
extension Recipe {
    // Stable UUIDs for dummy recipes
    private static let stableIDs: [UUID] = [
        UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567801")!,
        UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567802")!,
        UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567803")!,
        UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567804")!,
        UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567805")!,
        UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567806")!
    ]
    
    static var dummyData: [Recipe] = [
        Recipe(
            id: stableIDs[0],
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
            id: stableIDs[1],
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
            id: stableIDs[2],
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
        ),
        Recipe(
            id: stableIDs[3],
            title: "Pasta Carbonara",
            description: "A classic Italian pasta dish with a creamy egg sauce, pancetta, and cheese.",
            imageNamePlaceholder: "pasta_carbonara",
            ingredients: [
                "200g spaghetti",
                "100g pancetta or bacon, diced",
                "2 large eggs",
                "50g Pecorino Romano cheese, grated",
                "50g Parmesan cheese, grated",
                "2 cloves garlic, minced",
                "Freshly ground black pepper",
                "Salt to taste",
                "Fresh parsley, chopped (for garnish)"
            ],
            steps: [
                "Bring a large pot of salted water to boil and cook pasta according to package instructions",
                "While pasta is cooking, heat a large skillet over medium heat and cook pancetta until crispy",
                "In a bowl, whisk together eggs, grated cheeses, and black pepper",
                "Drain pasta, reserving 1/2 cup of pasta water",
                "Working quickly, add hot pasta to the skillet with pancetta, remove from heat",
                "Pour egg mixture over pasta, stirring constantly to create a creamy sauce",
                "Add a splash of pasta water if needed to loosen the sauce",
                "Serve immediately with extra cheese and chopped parsley"
            ],
            prepTime: 10,
            cookTime: 15,
            macros: MacroNutrients(protein: 24, carbs: 65, fats: 22, calories: 550)
        ),
        Recipe(
            id: stableIDs[4],
            title: "Chicken Stir Fry",
            description: "A quick and healthy stir fry with tender chicken and crisp vegetables in a savory sauce.",
            imageNamePlaceholder: "chicken_stir_fry",
            ingredients: [
                "500g chicken breast, sliced",
                "1 red bell pepper, sliced",
                "1 yellow bell pepper, sliced",
                "1 cup broccoli florets",
                "1 carrot, julienned",
                "3 cloves garlic, minced",
                "1 tbsp ginger, grated",
                "3 tbsp soy sauce",
                "1 tbsp oyster sauce",
                "1 tsp sesame oil",
                "2 tbsp vegetable oil",
                "Green onions, sliced (for garnish)"
            ],
            steps: [
                "In a small bowl, mix soy sauce, oyster sauce, and sesame oil",
                "Heat vegetable oil in a wok or large skillet over high heat",
                "Add chicken and stir fry until nearly cooked through, about 4-5 minutes",
                "Add garlic and ginger, stir fry for 30 seconds until fragrant",
                "Add all vegetables and stir fry for 3-4 minutes until crisp-tender",
                "Pour sauce over the chicken and vegetables, toss to coat",
                "Cook for another 1-2 minutes until everything is well combined and heated through",
                "Garnish with sliced green onions and serve with rice"
            ],
            prepTime: 15,
            cookTime: 10,
            macros: MacroNutrients(protein: 35, carbs: 15, fats: 12, calories: 310)
        ),
        Recipe(
            id: stableIDs[5],
            title: "Mushroom Risotto",
            description: "A creamy, comforting Italian rice dish with earthy mushrooms and Parmesan cheese.",
            imageNamePlaceholder: "mushroom_risotto",
            ingredients: [
                "1.5 cups Arborio rice",
                "500g mixed mushrooms (cremini, shiitake, oyster), sliced",
                "1 onion, finely diced",
                "2 cloves garlic, minced",
                "4 cups vegetable or chicken broth, warm",
                "1/2 cup dry white wine",
                "50g Parmesan cheese, grated",
                "2 tbsp butter",
                "2 tbsp olive oil",
                "Fresh thyme leaves",
                "Salt and pepper to taste"
            ],
            steps: [
                "In a large pan, heat 1 tbsp olive oil and sauté mushrooms until golden, then set aside",
                "In the same pan, heat remaining olive oil and butter, add onion and cook until translucent",
                "Add garlic and cook for 30 seconds until fragrant",
                "Add Arborio rice and stir to coat with oil, toast for 1-2 minutes",
                "Pour in wine and stir until absorbed",
                "Add warm broth one ladle at a time, stirring frequently and waiting until liquid is absorbed before adding more",
                "Continue this process for about 18-20 minutes until rice is creamy but still al dente",
                "Stir in cooked mushrooms, Parmesan cheese, and thyme leaves",
                "Season with salt and pepper, serve immediately"
            ],
            prepTime: 10,
            cookTime: 30,
            macros: MacroNutrients(protein: 12, carbs: 65, fats: 15, calories: 420)
        )
    ]
} 