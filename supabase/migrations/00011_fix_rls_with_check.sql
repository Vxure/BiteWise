-- ============================================================================
-- BiteWise Database Schema - Fix RLS Policies WITH CHECK
-- Migration: 00011_fix_rls_with_check.sql
-- Description: Adds WITH CHECK clause to FOR ALL policies for INSERT validation
-- 
-- WHY: Policies with FOR ALL and only USING clause do not validate INSERT.
-- The USING clause applies to SELECT/UPDATE/DELETE, but INSERT requires
-- WITH CHECK to validate that new rows satisfy the policy.
-- ============================================================================

-- ============================================================================
-- 1. USER_SETTINGS - Add WITH CHECK for INSERT
-- ============================================================================

-- Drop and recreate with both USING and WITH CHECK
DROP POLICY IF EXISTS "Users can manage own settings" ON public.user_settings;

CREATE POLICY "Users can manage own settings"
    ON public.user_settings FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 2. FRIDGE_SCANS - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own fridge scans" ON public.fridge_scans;

CREATE POLICY "Users can manage own fridge scans"
    ON public.fridge_scans FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 3. FRIDGE_ITEMS - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own fridge items" ON public.fridge_items;

CREATE POLICY "Users can manage own fridge items"
    ON public.fridge_items FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 4. PANTRY_ITEMS - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own pantry items" ON public.pantry_items;

CREATE POLICY "Users can manage own pantry items"
    ON public.pantry_items FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 5. SAVED_RECIPES - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own saved recipes" ON public.saved_recipes;

CREATE POLICY "Users can manage own saved recipes"
    ON public.saved_recipes FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 6. RECIPE_HISTORY - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own recipe history" ON public.recipe_history;

CREATE POLICY "Users can manage own recipe history"
    ON public.recipe_history FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 7. RECIPE_FEEDBACK - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own recipe feedback" ON public.recipe_feedback;

CREATE POLICY "Users can manage own recipe feedback"
    ON public.recipe_feedback FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 8. CHAT_SESSIONS - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own chat sessions" ON public.chat_sessions;

CREATE POLICY "Users can manage own chat sessions"
    ON public.chat_sessions FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 9. CHAT_MESSAGES - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own chat messages" ON public.chat_messages;

CREATE POLICY "Users can manage own chat messages"
    ON public.chat_messages FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 10. DAILY_MACRO_LOGS - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own macro logs" ON public.daily_macro_logs;

CREATE POLICY "Users can manage own macro logs"
    ON public.daily_macro_logs FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 11. ACTIVITY_FEED - Add WITH CHECK for INSERT
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own activity feed" ON public.activity_feed;

CREATE POLICY "Users can manage own activity feed"
    ON public.activity_feed FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 12. PROFILES - Restrict "view all" to only name/avatar (security fix)
-- 
-- The original "Users can view all profiles" policy exposed all profile data.
-- This is too permissive. For social features, we should:
-- 1. Keep user's own profile fully accessible
-- 2. Only expose minimal public info for other users via API/view
-- 
-- For now, we'll remove the overly permissive policy. Social features
-- should use a restricted view or API endpoint instead.
-- ============================================================================

DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;

-- Note: "Users can view own profile" policy remains, which is sufficient
-- for the current app functionality. Social features should be implemented
-- with a separate public_profiles view that only exposes name and avatar_url.

-- RLS policies updated with WITH CHECK for INSERT validation
