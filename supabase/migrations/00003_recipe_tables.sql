-- ============================================================================
-- BiteWise Database Schema - Recipe Tables
-- Migration: 00003_recipe_tables.sql
-- Description: Creates recipes, saved_recipes, recipe_history, recipe_feedback
-- ============================================================================

-- ============================================================================
-- 1. RECIPES TABLE
-- Maps to Recipe.swift
-- ============================================================================

CREATE TABLE public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image_path TEXT,
    prep_time INTEGER DEFAULT 0,
    cook_time INTEGER DEFAULT 0,
    servings INTEGER DEFAULT 2,
    
    -- Macros (matches MacroNutrients struct in Recipe.swift)
    calories INTEGER DEFAULT 0,
    protein DECIMAL(6,2) DEFAULT 0,
    carbs DECIMAL(6,2) DEFAULT 0,
    fats DECIMAL(6,2) DEFAULT 0,
    
    -- JSONB for flexible content (matches Swift [String] arrays)
    -- ingredients: ["1 cup flour", "2 eggs", ...]
    -- steps: ["Preheat oven...", "Mix ingredients...", ...]
    ingredients JSONB DEFAULT '[]',
    steps JSONB DEFAULT '[]',
    
    -- Visibility and source flags
    is_public BOOLEAN DEFAULT false,
    is_ai_generated BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_recipes_user ON public.recipes(user_id);
CREATE INDEX idx_recipes_public ON public.recipes(is_public) WHERE is_public = true;
CREATE INDEX idx_recipes_created ON public.recipes(created_at DESC);
CREATE INDEX idx_recipes_user_created ON public.recipes(user_id, created_at DESC);
CREATE INDEX idx_recipes_title ON public.recipes USING gin(to_tsvector('english', title));
CREATE INDEX idx_recipes_ingredients ON public.recipes USING gin(ingredients);

-- Auto-update updated_at
CREATE TRIGGER update_recipes_updated_at
    BEFORE UPDATE ON public.recipes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 2. SAVED_RECIPES TABLE (favorites)
-- Maps to DataManager.favoriteRecipes
-- ============================================================================

CREATE TABLE public.saved_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE NOT NULL,
    saved_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- Prevent duplicate favorites
    CONSTRAINT unique_user_saved_recipe UNIQUE (user_id, recipe_id)
);

-- Enable RLS
ALTER TABLE public.saved_recipes ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_saved_recipes_user ON public.saved_recipes(user_id);
CREATE INDEX idx_saved_recipes_recipe ON public.saved_recipes(recipe_id);
CREATE INDEX idx_saved_recipes_user_date ON public.saved_recipes(user_id, saved_at DESC);

-- ============================================================================
-- 3. RECIPE_HISTORY TABLE (cooked recipes)
-- Maps to DataManager.cookedRecipeIDs and recipeHistory
-- ============================================================================

CREATE TABLE public.recipe_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE NOT NULL,
    cooked_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT
);

-- Enable RLS
ALTER TABLE public.recipe_history ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_recipe_history_user ON public.recipe_history(user_id);
CREATE INDEX idx_recipe_history_recipe ON public.recipe_history(recipe_id);
CREATE INDEX idx_recipe_history_date ON public.recipe_history(cooked_at DESC);
CREATE INDEX idx_recipe_history_user_date ON public.recipe_history(user_id, cooked_at DESC);

-- ============================================================================
-- 4. RECIPE_FEEDBACK TABLE (detailed feedback)
-- Maps to RecipeFeedback struct in DataManager.swift
-- ============================================================================

CREATE TABLE public.recipe_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE NOT NULL,
    recipe_name TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    enjoyed BOOLEAN,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- One feedback per user per recipe
    CONSTRAINT unique_user_recipe_feedback UNIQUE (user_id, recipe_id)
);

-- Enable RLS
ALTER TABLE public.recipe_feedback ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_recipe_feedback_user ON public.recipe_feedback(user_id);
CREATE INDEX idx_recipe_feedback_recipe ON public.recipe_feedback(recipe_id);
CREATE INDEX idx_recipe_feedback_rating ON public.recipe_feedback(rating);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.recipes IS 'Recipe storage - user-created, AI-generated, or system templates';
COMMENT ON TABLE public.saved_recipes IS 'User favorites/bookmarks for recipes';
COMMENT ON TABLE public.recipe_history IS 'Log of when users cooked recipes';
COMMENT ON TABLE public.recipe_feedback IS 'Detailed user feedback on recipes';

COMMENT ON COLUMN public.recipes.user_id IS 'NULL for system/template recipes';
COMMENT ON COLUMN public.recipes.ingredients IS 'JSONB array of ingredient strings: ["1 cup flour", ...]';
COMMENT ON COLUMN public.recipes.steps IS 'JSONB array of step strings: ["Preheat oven...", ...]';
COMMENT ON COLUMN public.recipes.is_public IS 'If true, recipe is visible to all users';
COMMENT ON COLUMN public.recipes.is_ai_generated IS 'If true, recipe was generated by AI';
COMMENT ON COLUMN public.recipe_history.rating IS 'Quick rating at cook time (1-5 stars)';
COMMENT ON COLUMN public.recipe_feedback.recipe_name IS 'Denormalized for display even if recipe is deleted';
