-- ============================================================================
-- BiteWise Database Schema - Row Level Security Policies
-- Migration: 00006_rls_policies.sql
-- Description: Applies RLS policies to all tables
-- ============================================================================

-- ============================================================================
-- 1. PROFILES POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Allow viewing other profiles for future social features (name/avatar only via API)
CREATE POLICY "Users can view all profiles"
    ON public.profiles FOR SELECT
    USING (true);

-- ============================================================================
-- 2. USER_PREFERENCES POLICIES
-- ============================================================================

-- Users can view their own preferences
CREATE POLICY "Users can view own preferences"
    ON public.user_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences"
    ON public.user_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences"
    ON public.user_preferences FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "Users can delete own preferences"
    ON public.user_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 3. USER_SETTINGS POLICIES
-- ============================================================================

-- Users can manage their own settings (all operations)
CREATE POLICY "Users can manage own settings"
    ON public.user_settings FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 4. INGREDIENTS POLICIES (shared catalog - public read)
-- ============================================================================

-- Anyone authenticated can read ingredients
CREATE POLICY "Anyone can read ingredients"
    ON public.ingredients FOR SELECT
    USING (true);

-- Note: INSERT/UPDATE/DELETE for ingredients should be admin-only via service role

-- ============================================================================
-- 5. FRIDGE_SCANS POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own fridge scans"
    ON public.fridge_scans FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 6. FRIDGE_ITEMS POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own fridge items"
    ON public.fridge_items FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 7. PANTRY_ITEMS POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own pantry items"
    ON public.pantry_items FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 8. RECIPES POLICIES
-- ============================================================================

-- Users can read their own recipes
CREATE POLICY "Users can read own recipes"
    ON public.recipes FOR SELECT
    USING (auth.uid() = user_id);

-- Users can read public recipes
CREATE POLICY "Users can read public recipes"
    ON public.recipes FOR SELECT
    USING (is_public = true);

-- Users can read system recipes (no owner)
CREATE POLICY "Users can read system recipes"
    ON public.recipes FOR SELECT
    USING (user_id IS NULL);

-- Users can create their own recipes
CREATE POLICY "Users can create own recipes"
    ON public.recipes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own recipes
CREATE POLICY "Users can update own recipes"
    ON public.recipes FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own recipes
CREATE POLICY "Users can delete own recipes"
    ON public.recipes FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 9. SAVED_RECIPES POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own saved recipes"
    ON public.saved_recipes FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 10. RECIPE_HISTORY POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own recipe history"
    ON public.recipe_history FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 11. RECIPE_FEEDBACK POLICIES
-- ============================================================================

-- Users can manage their own feedback
CREATE POLICY "Users can manage own recipe feedback"
    ON public.recipe_feedback FOR ALL
    USING (auth.uid() = user_id);

-- Recipe owners can read feedback on their public recipes
CREATE POLICY "Recipe owners can read feedback on their recipes"
    ON public.recipe_feedback FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.recipes 
            WHERE recipes.id = recipe_feedback.recipe_id 
            AND recipes.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 12. CHAT_SESSIONS POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own chat sessions"
    ON public.chat_sessions FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 13. CHAT_MESSAGES POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own chat messages"
    ON public.chat_messages FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 14. DAILY_MACRO_LOGS POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own macro logs"
    ON public.daily_macro_logs FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- 15. ACTIVITY_FEED POLICIES
-- ============================================================================

CREATE POLICY "Users can manage own activity feed"
    ON public.activity_feed FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON POLICY "Users can view all profiles" ON public.profiles IS 
    'Allows viewing basic profile info for social features - restrict fields via API';

COMMENT ON POLICY "Anyone can read ingredients" ON public.ingredients IS 
    'Ingredients is a shared catalog - all authenticated users can read';

COMMENT ON POLICY "Users can read public recipes" ON public.recipes IS 
    'Public recipes are visible to all authenticated users for discovery';

COMMENT ON POLICY "Recipe owners can read feedback on their recipes" ON public.recipe_feedback IS 
    'Recipe creators can see feedback on their recipes for improvement';
