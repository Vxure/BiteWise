-- ============================================================================
-- BiteWise Database Schema - Seed Ingredients Catalog
-- Migration: 00010_seed_ingredients.sql
-- Description: Seeds the ingredients table with common food items
-- ============================================================================

-- ============================================================================
-- PROTEINS
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Chicken Breast', 'chicken breast', 'protein', true),
    ('Chicken Thighs', 'chicken thighs', 'protein', true),
    ('Ground Beef', 'ground beef', 'protein', true),
    ('Beef Steak', 'beef steak', 'protein', true),
    ('Pork Chops', 'pork chops', 'protein', true),
    ('Ground Pork', 'ground pork', 'protein', false),
    ('Bacon', 'bacon', 'protein', true),
    ('Pancetta', 'pancetta', 'protein', false),
    ('Salmon', 'salmon', 'protein', true),
    ('Tuna', 'tuna', 'protein', true),
    ('Shrimp', 'shrimp', 'protein', true),
    ('Cod', 'cod', 'protein', false),
    ('Tilapia', 'tilapia', 'protein', false),
    ('Turkey Breast', 'turkey breast', 'protein', true),
    ('Ground Turkey', 'ground turkey', 'protein', true),
    ('Lamb', 'lamb', 'protein', false),
    ('Tofu', 'tofu', 'protein', true),
    ('Tempeh', 'tempeh', 'protein', false),
    ('Eggs', 'eggs', 'protein', true),
    ('Egg Whites', 'egg whites', 'protein', false),
    ('Sausage', 'sausage', 'protein', true),
    ('Ham', 'ham', 'protein', true),
    ('Deli Turkey', 'deli turkey', 'protein', false),
    ('Rotisserie Chicken', 'rotisserie chicken', 'protein', false)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- DAIRY
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Milk', 'milk', 'dairy', true),
    ('Butter', 'butter', 'dairy', true),
    ('Heavy Cream', 'heavy cream', 'dairy', true),
    ('Sour Cream', 'sour cream', 'dairy', true),
    ('Greek Yogurt', 'greek yogurt', 'dairy', true),
    ('Plain Yogurt', 'plain yogurt', 'dairy', false),
    ('Cheddar Cheese', 'cheddar cheese', 'dairy', true),
    ('Mozzarella Cheese', 'mozzarella cheese', 'dairy', true),
    ('Parmesan Cheese', 'parmesan cheese', 'dairy', true),
    ('Feta Cheese', 'feta cheese', 'dairy', true),
    ('Cream Cheese', 'cream cheese', 'dairy', true),
    ('Cottage Cheese', 'cottage cheese', 'dairy', false),
    ('Ricotta Cheese', 'ricotta cheese', 'dairy', false),
    ('Swiss Cheese', 'swiss cheese', 'dairy', false),
    ('Goat Cheese', 'goat cheese', 'dairy', false),
    ('Blue Cheese', 'blue cheese', 'dairy', false),
    ('Shredded Cheese', 'shredded cheese', 'dairy', true),
    ('Half and Half', 'half and half', 'dairy', false),
    ('Almond Milk', 'almond milk', 'dairy', true),
    ('Oat Milk', 'oat milk', 'dairy', false),
    ('Coconut Milk', 'coconut milk', 'dairy', true)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- VEGETABLES
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Onion', 'onion', 'vegetable', true),
    ('Garlic', 'garlic', 'vegetable', true),
    ('Tomatoes', 'tomatoes', 'vegetable', true),
    ('Cherry Tomatoes', 'cherry tomatoes', 'vegetable', true),
    ('Bell Pepper', 'bell pepper', 'vegetable', true),
    ('Red Bell Pepper', 'red bell pepper', 'vegetable', false),
    ('Jalapeno', 'jalapeno', 'vegetable', false),
    ('Spinach', 'spinach', 'vegetable', true),
    ('Kale', 'kale', 'vegetable', true),
    ('Lettuce', 'lettuce', 'vegetable', true),
    ('Romaine Lettuce', 'romaine lettuce', 'vegetable', false),
    ('Arugula', 'arugula', 'vegetable', false),
    ('Broccoli', 'broccoli', 'vegetable', true),
    ('Cauliflower', 'cauliflower', 'vegetable', true),
    ('Carrots', 'carrots', 'vegetable', true),
    ('Celery', 'celery', 'vegetable', true),
    ('Cucumber', 'cucumber', 'vegetable', true),
    ('Zucchini', 'zucchini', 'vegetable', true),
    ('Mushrooms', 'mushrooms', 'vegetable', true),
    ('Asparagus', 'asparagus', 'vegetable', false),
    ('Green Beans', 'green beans', 'vegetable', true),
    ('Peas', 'peas', 'vegetable', true),
    ('Corn', 'corn', 'vegetable', true),
    ('Potatoes', 'potatoes', 'vegetable', true),
    ('Sweet Potatoes', 'sweet potatoes', 'vegetable', true),
    ('Cabbage', 'cabbage', 'vegetable', false),
    ('Brussels Sprouts', 'brussels sprouts', 'vegetable', false),
    ('Eggplant', 'eggplant', 'vegetable', false),
    ('Squash', 'squash', 'vegetable', false),
    ('Butternut Squash', 'butternut squash', 'vegetable', false),
    ('Avocado', 'avocado', 'vegetable', true),
    ('Green Onions', 'green onions', 'vegetable', true),
    ('Leeks', 'leeks', 'vegetable', false),
    ('Shallots', 'shallots', 'vegetable', false),
    ('Ginger', 'ginger', 'vegetable', true),
    ('Mixed Greens', 'mixed greens', 'vegetable', true)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- FRUITS
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Apples', 'apples', 'fruit', true),
    ('Bananas', 'bananas', 'fruit', true),
    ('Oranges', 'oranges', 'fruit', true),
    ('Lemons', 'lemons', 'fruit', true),
    ('Limes', 'limes', 'fruit', true),
    ('Strawberries', 'strawberries', 'fruit', true),
    ('Blueberries', 'blueberries', 'fruit', true),
    ('Raspberries', 'raspberries', 'fruit', false),
    ('Blackberries', 'blackberries', 'fruit', false),
    ('Mixed Berries', 'mixed berries', 'fruit', true),
    ('Grapes', 'grapes', 'fruit', true),
    ('Watermelon', 'watermelon', 'fruit', false),
    ('Cantaloupe', 'cantaloupe', 'fruit', false),
    ('Pineapple', 'pineapple', 'fruit', true),
    ('Mango', 'mango', 'fruit', true),
    ('Peaches', 'peaches', 'fruit', false),
    ('Pears', 'pears', 'fruit', false),
    ('Cherries', 'cherries', 'fruit', false),
    ('Kiwi', 'kiwi', 'fruit', false),
    ('Pomegranate', 'pomegranate', 'fruit', false)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- GRAINS & STARCHES
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Rice', 'rice', 'grain', true),
    ('Brown Rice', 'brown rice', 'grain', true),
    ('Jasmine Rice', 'jasmine rice', 'grain', false),
    ('Arborio Rice', 'arborio rice', 'grain', false),
    ('Quinoa', 'quinoa', 'grain', true),
    ('Pasta', 'pasta', 'grain', true),
    ('Spaghetti', 'spaghetti', 'grain', true),
    ('Penne', 'penne', 'grain', false),
    ('Fettuccine', 'fettuccine', 'grain', false),
    ('Linguine', 'linguine', 'grain', false),
    ('Macaroni', 'macaroni', 'grain', false),
    ('Bread', 'bread', 'grain', true),
    ('Whole Wheat Bread', 'whole wheat bread', 'grain', false),
    ('Tortillas', 'tortillas', 'grain', true),
    ('Flour Tortillas', 'flour tortillas', 'grain', false),
    ('Corn Tortillas', 'corn tortillas', 'grain', false),
    ('Oats', 'oats', 'grain', true),
    ('Flour', 'flour', 'grain', true),
    ('Bread Crumbs', 'bread crumbs', 'grain', false),
    ('Panko', 'panko', 'grain', false),
    ('Couscous', 'couscous', 'grain', false),
    ('Bulgur', 'bulgur', 'grain', false),
    ('Noodles', 'noodles', 'grain', true),
    ('Rice Noodles', 'rice noodles', 'grain', false),
    ('Crackers', 'crackers', 'grain', false)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- CONDIMENTS & SAUCES
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Olive Oil', 'olive oil', 'condiment', true),
    ('Vegetable Oil', 'vegetable oil', 'condiment', true),
    ('Coconut Oil', 'coconut oil', 'condiment', false),
    ('Sesame Oil', 'sesame oil', 'condiment', true),
    ('Salt', 'salt', 'condiment', true),
    ('Pepper', 'pepper', 'condiment', true),
    ('Black Pepper', 'black pepper', 'condiment', true),
    ('Soy Sauce', 'soy sauce', 'condiment', true),
    ('Fish Sauce', 'fish sauce', 'condiment', false),
    ('Hot Sauce', 'hot sauce', 'condiment', true),
    ('Sriracha', 'sriracha', 'condiment', true),
    ('Ketchup', 'ketchup', 'condiment', true),
    ('Mustard', 'mustard', 'condiment', true),
    ('Dijon Mustard', 'dijon mustard', 'condiment', false),
    ('Mayonnaise', 'mayonnaise', 'condiment', true),
    ('Vinegar', 'vinegar', 'condiment', true),
    ('Balsamic Vinegar', 'balsamic vinegar', 'condiment', true),
    ('Rice Vinegar', 'rice vinegar', 'condiment', false),
    ('Apple Cider Vinegar', 'apple cider vinegar', 'condiment', false),
    ('Honey', 'honey', 'condiment', true),
    ('Maple Syrup', 'maple syrup', 'condiment', true),
    ('Sugar', 'sugar', 'condiment', true),
    ('Brown Sugar', 'brown sugar', 'condiment', false),
    ('Worcestershire Sauce', 'worcestershire sauce', 'condiment', false),
    ('Oyster Sauce', 'oyster sauce', 'condiment', false),
    ('Hoisin Sauce', 'hoisin sauce', 'condiment', false),
    ('Teriyaki Sauce', 'teriyaki sauce', 'condiment', false),
    ('BBQ Sauce', 'bbq sauce', 'condiment', true),
    ('Tomato Sauce', 'tomato sauce', 'condiment', true),
    ('Tomato Paste', 'tomato paste', 'condiment', true),
    ('Marinara Sauce', 'marinara sauce', 'condiment', true),
    ('Pesto', 'pesto', 'condiment', false),
    ('Salsa', 'salsa', 'condiment', true),
    ('Ranch Dressing', 'ranch dressing', 'condiment', true),
    ('Italian Dressing', 'italian dressing', 'condiment', false),
    ('Tahini', 'tahini', 'condiment', false),
    ('Hummus', 'hummus', 'condiment', true)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- HERBS & SPICES (as condiments)
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Basil', 'basil', 'condiment', true),
    ('Fresh Basil', 'fresh basil', 'condiment', false),
    ('Oregano', 'oregano', 'condiment', true),
    ('Thyme', 'thyme', 'condiment', true),
    ('Rosemary', 'rosemary', 'condiment', true),
    ('Parsley', 'parsley', 'condiment', true),
    ('Cilantro', 'cilantro', 'condiment', true),
    ('Dill', 'dill', 'condiment', false),
    ('Mint', 'mint', 'condiment', false),
    ('Chives', 'chives', 'condiment', false),
    ('Bay Leaves', 'bay leaves', 'condiment', false),
    ('Cumin', 'cumin', 'condiment', true),
    ('Paprika', 'paprika', 'condiment', true),
    ('Smoked Paprika', 'smoked paprika', 'condiment', false),
    ('Chili Powder', 'chili powder', 'condiment', true),
    ('Cayenne Pepper', 'cayenne pepper', 'condiment', false),
    ('Red Pepper Flakes', 'red pepper flakes', 'condiment', true),
    ('Cinnamon', 'cinnamon', 'condiment', true),
    ('Nutmeg', 'nutmeg', 'condiment', false),
    ('Turmeric', 'turmeric', 'condiment', false),
    ('Curry Powder', 'curry powder', 'condiment', true),
    ('Garam Masala', 'garam masala', 'condiment', false),
    ('Italian Seasoning', 'italian seasoning', 'condiment', true),
    ('Garlic Powder', 'garlic powder', 'condiment', true),
    ('Onion Powder', 'onion powder', 'condiment', true)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- BEVERAGES
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Coffee', 'coffee', 'beverage', true),
    ('Tea', 'tea', 'beverage', true),
    ('Orange Juice', 'orange juice', 'beverage', true),
    ('Apple Juice', 'apple juice', 'beverage', false),
    ('Lemon Juice', 'lemon juice', 'beverage', true),
    ('Lime Juice', 'lime juice', 'beverage', true),
    ('Chicken Broth', 'chicken broth', 'beverage', true),
    ('Vegetable Broth', 'vegetable broth', 'beverage', true),
    ('Beef Broth', 'beef broth', 'beverage', false),
    ('White Wine', 'white wine', 'beverage', false),
    ('Red Wine', 'red wine', 'beverage', false),
    ('Beer', 'beer', 'beverage', false)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- OTHER / PANTRY STAPLES
-- ============================================================================

INSERT INTO public.ingredients (name, normalized_name, category, is_common) VALUES
    ('Canned Beans', 'canned beans', 'other', true),
    ('Black Beans', 'black beans', 'other', true),
    ('Kidney Beans', 'kidney beans', 'other', false),
    ('Chickpeas', 'chickpeas', 'other', true),
    ('Lentils', 'lentils', 'other', false),
    ('Canned Tomatoes', 'canned tomatoes', 'other', true),
    ('Diced Tomatoes', 'diced tomatoes', 'other', true),
    ('Crushed Tomatoes', 'crushed tomatoes', 'other', false),
    ('Coconut Cream', 'coconut cream', 'other', false),
    ('Nuts', 'nuts', 'other', true),
    ('Almonds', 'almonds', 'other', true),
    ('Walnuts', 'walnuts', 'other', false),
    ('Peanuts', 'peanuts', 'other', true),
    ('Cashews', 'cashews', 'other', false),
    ('Pine Nuts', 'pine nuts', 'other', false),
    ('Peanut Butter', 'peanut butter', 'other', true),
    ('Almond Butter', 'almond butter', 'other', false),
    ('Seeds', 'seeds', 'other', false),
    ('Chia Seeds', 'chia seeds', 'other', false),
    ('Flax Seeds', 'flax seeds', 'other', false),
    ('Sesame Seeds', 'sesame seeds', 'other', false),
    ('Sunflower Seeds', 'sunflower seeds', 'other', false),
    ('Raisins', 'raisins', 'other', false),
    ('Dried Cranberries', 'dried cranberries', 'other', false),
    ('Chocolate Chips', 'chocolate chips', 'other', false),
    ('Cocoa Powder', 'cocoa powder', 'other', false),
    ('Vanilla Extract', 'vanilla extract', 'other', true),
    ('Baking Powder', 'baking powder', 'other', true),
    ('Baking Soda', 'baking soda', 'other', true),
    ('Yeast', 'yeast', 'other', false),
    ('Cornstarch', 'cornstarch', 'other', true),
    ('Granola', 'granola', 'other', true)
ON CONFLICT (normalized_name) DO NOTHING;

-- ============================================================================
-- SUMMARY
-- ============================================================================

-- Count ingredients by category
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM public.ingredients;
    RAISE NOTICE 'Total ingredients seeded: %', v_count;
END $$;
