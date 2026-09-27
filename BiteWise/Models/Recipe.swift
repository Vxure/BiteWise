import Foundation

struct MacroNutrients: Hashable, Codable {
    var protein: Double
    var carbs: Double
    var fats: Double
    var calories: Int
}

struct CookingStep: Hashable, Codable {
    var title: String
    var instruction: String
    var durationMinutes: Int
    var ingredients: [String]
    var chefTip: String
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
    var cookingSteps: [CookingStep]?
    
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
            macros: MacroNutrients(protein: 32, carbs: 8, fats: 14, calories: 320),
            cookingSteps: [
                CookingStep(title: "Season the chicken", instruction: "Season chicken breasts with salt and pepper on both sides.", durationMinutes: 2, ingredients: ["2 chicken breasts", "Salt and pepper to taste"], chefTip: "Pat the chicken dry with paper towels first for better seasoning adhesion."),
                CookingStep(title: "Grill the chicken", instruction: "Grill chicken for 6-7 minutes on each side until cooked through.", durationMinutes: 14, ingredients: ["2 chicken breasts"], chefTip: "Don't press down on the chicken -- let it develop a nice char naturally."),
                CookingStep(title: "Prep the vegetables", instruction: "While chicken rests, chop spinach and halve cherry tomatoes.", durationMinutes: 5, ingredients: ["1 cup spinach", "1/2 cup cherry tomatoes"], chefTip: "Tear spinach by hand instead of cutting for a more rustic texture."),
                CookingStep(title: "Slice the chicken", instruction: "Let the chicken rest for 3 minutes, then slice against the grain.", durationMinutes: 4, ingredients: ["2 chicken breasts"], chefTip: "Slicing against the grain keeps the meat tender and easy to chew."),
                CookingStep(title: "Assemble the salad", instruction: "Combine spinach, tomatoes, sliced chicken, and feta cheese in a large bowl.", durationMinutes: 2, ingredients: ["1 cup spinach", "1/2 cup cherry tomatoes", "1/4 cup feta cheese"], chefTip: "Crumble the feta by hand for uneven pieces that catch the dressing better."),
                CookingStep(title: "Dress and serve", instruction: "Drizzle with olive oil and lemon juice. Toss gently and serve immediately.", durationMinutes: 1, ingredients: ["2 tbsp olive oil", "1 tbsp lemon juice"], chefTip: "Add the dressing just before serving so the spinach stays crisp.")
            ]
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
            macros: MacroNutrients(protein: 24, carbs: 65, fats: 22, calories: 550),
            cookingSteps: [
                CookingStep(title: "Boil the pasta", instruction: "Bring a large pot of salted water to a rolling boil and cook spaghetti according to package instructions until al dente.", durationMinutes: 10, ingredients: ["200g spaghetti", "Salt to taste"], chefTip: "Salt the water generously -- it should taste like the sea. This is your only chance to season the pasta itself."),
                CookingStep(title: "Cook the pancetta", instruction: "While pasta is cooking, heat a large skillet over medium heat and cook diced pancetta until crispy and golden, about 5 minutes.", durationMinutes: 5, ingredients: ["100g pancetta or bacon, diced", "2 cloves garlic, minced"], chefTip: "Start with a cold pan so the fat renders slowly, giving you crispier pancetta."),
                CookingStep(title: "Prepare the egg mixture", instruction: "In a bowl, whisk together eggs, grated Pecorino and Parmesan, and a generous amount of black pepper until smooth.", durationMinutes: 2, ingredients: ["2 large eggs", "50g Pecorino Romano cheese, grated", "50g Parmesan cheese, grated", "Freshly ground black pepper"], chefTip: "Use room-temperature eggs to prevent them from scrambling when they hit the hot pasta."),
                CookingStep(title: "Drain the pasta", instruction: "Drain the pasta, reserving about 1/2 cup of the starchy pasta water. This liquid gold helps create the sauce.", durationMinutes: 1, ingredients: ["200g spaghetti"], chefTip: "Always save more pasta water than you think you'll need -- you can't get it back once it's gone."),
                CookingStep(title: "Combine pasta and pancetta", instruction: "Working quickly, add the hot drained pasta to the skillet with the pancetta. Remove the pan from heat immediately.", durationMinutes: 1, ingredients: ["200g spaghetti", "100g pancetta or bacon, diced"], chefTip: "Removing from heat is critical -- too much heat will scramble the eggs in the next step."),
                CookingStep(title: "Create the sauce", instruction: "Pour the egg and cheese mixture over the hot pasta, stirring and tossing constantly to create a silky, creamy sauce.", durationMinutes: 2, ingredients: ["2 large eggs", "50g Pecorino Romano cheese, grated", "50g Parmesan cheese, grated"], chefTip: "Toss vigorously -- the residual heat gently cooks the eggs into a velvety coating, not scrambled bits."),
                CookingStep(title: "Adjust consistency", instruction: "Add a splash of reserved pasta water if the sauce is too thick. Stir until you reach a glossy, coat-the-noodle consistency.", durationMinutes: 1, ingredients: [], chefTip: "Add pasta water a tablespoon at a time -- you can always add more but can't take it away."),
                CookingStep(title: "Plate and garnish", instruction: "Serve immediately on warmed plates with extra grated cheese and fresh chopped parsley on top.", durationMinutes: 1, ingredients: ["50g Parmesan cheese, grated", "Fresh parsley, chopped (for garnish)"], chefTip: "Warm your plates in the oven for a minute -- carbonara cools quickly and cold plates speed that up.")
            ]
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