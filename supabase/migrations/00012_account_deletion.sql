-- Migration: Account Deletion RPC
-- Description: Creates RPC functions to delete all user data for account deletion
-- Updated: Now includes idempotent design and admin version for job processor

-- ============================================================================
-- 1. USER-CALLABLE FUNCTION (uses auth.uid())
-- ============================================================================

-- RPC function to delete user account and all associated data
-- This function is idempotent - safe to call multiple times
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id UUID;
    deleted_counts JSON;
BEGIN
    -- Get the current authenticated user's ID
    current_user_id := auth.uid();
    
    -- Ensure user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Call the internal deletion function
    RETURN public._delete_user_data_internal(current_user_id);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- Explicitly revoke from anonymous and public roles
REVOKE ALL ON FUNCTION public.delete_user_account() FROM anon;
REVOKE ALL ON FUNCTION public.delete_user_account() FROM public;

-- Add comment for documentation
COMMENT ON FUNCTION public.delete_user_account() IS 
    'Deletes all data associated with the current authenticated user. Idempotent - safe to call multiple times.';

-- ============================================================================
-- 2. ADMIN-CALLABLE FUNCTION (for job processor Edge Function)
-- ============================================================================

-- Admin version that accepts a user_id parameter
-- Only callable by service role (no GRANT to authenticated)
CREATE OR REPLACE FUNCTION public.delete_user_account_admin(target_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Validate input
    IF target_user_id IS NULL THEN
        RAISE EXCEPTION 'target_user_id is required';
    END IF;
    
    -- Call the internal deletion function
    RETURN public._delete_user_data_internal(target_user_id);
END;
$$;

-- Only service role can call this (no GRANT to authenticated)
REVOKE ALL ON FUNCTION public.delete_user_account_admin(UUID) FROM authenticated;
REVOKE ALL ON FUNCTION public.delete_user_account_admin(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.delete_user_account_admin(UUID) FROM public;

COMMENT ON FUNCTION public.delete_user_account_admin(UUID) IS 
    'Admin version of delete_user_account for use by job processor. Service role only.';

-- ============================================================================
-- 3. INTERNAL DELETION FUNCTION (shared logic)
-- ============================================================================

-- Internal function that performs the actual deletion
-- Returns a JSON object with counts of deleted rows for each table
CREATE OR REPLACE FUNCTION public._delete_user_data_internal(target_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    chat_messages_count INTEGER := 0;
    chat_sessions_count INTEGER := 0;
    recipe_feedback_count INTEGER := 0;
    recipe_history_count INTEGER := 0;
    saved_recipes_count INTEGER := 0;
    recipes_count INTEGER := 0;
    macro_logs_count INTEGER := 0;
    activity_feed_count INTEGER := 0;
    fridge_items_count INTEGER := 0;
    fridge_scans_count INTEGER := 0;
    pantry_items_count INTEGER := 0;
    user_preferences_count INTEGER := 0;
    user_settings_count INTEGER := 0;
    profiles_count INTEGER := 0;
BEGIN
    -- Delete from all user-related tables
    -- Order matters due to foreign key constraints
    -- Each DELETE is idempotent - deleting 0 rows is fine
    
    -- Delete chat messages first (references chat_sessions)
    DELETE FROM public.chat_messages WHERE user_id = target_user_id;
    GET DIAGNOSTICS chat_messages_count = ROW_COUNT;
    
    -- Delete chat sessions
    DELETE FROM public.chat_sessions WHERE user_id = target_user_id;
    GET DIAGNOSTICS chat_sessions_count = ROW_COUNT;
    
    -- Delete recipe feedback
    DELETE FROM public.recipe_feedback WHERE user_id = target_user_id;
    GET DIAGNOSTICS recipe_feedback_count = ROW_COUNT;
    
    -- Delete recipe history
    DELETE FROM public.recipe_history WHERE user_id = target_user_id;
    GET DIAGNOSTICS recipe_history_count = ROW_COUNT;
    
    -- Delete saved recipes (favorites)
    DELETE FROM public.saved_recipes WHERE user_id = target_user_id;
    GET DIAGNOSTICS saved_recipes_count = ROW_COUNT;
    
    -- Delete recipes created by user
    DELETE FROM public.recipes WHERE user_id = target_user_id;
    GET DIAGNOSTICS recipes_count = ROW_COUNT;
    
    -- Delete daily macro logs
    DELETE FROM public.daily_macro_logs WHERE user_id = target_user_id;
    GET DIAGNOSTICS macro_logs_count = ROW_COUNT;
    
    -- Delete activity feed
    DELETE FROM public.activity_feed WHERE user_id = target_user_id;
    GET DIAGNOSTICS activity_feed_count = ROW_COUNT;
    
    -- Delete fridge scans
    DELETE FROM public.fridge_scans WHERE user_id = target_user_id;
    GET DIAGNOSTICS fridge_scans_count = ROW_COUNT;
    
    -- Delete fridge items
    DELETE FROM public.fridge_items WHERE user_id = target_user_id;
    GET DIAGNOSTICS fridge_items_count = ROW_COUNT;
    
    -- Delete pantry items
    DELETE FROM public.pantry_items WHERE user_id = target_user_id;
    GET DIAGNOSTICS pantry_items_count = ROW_COUNT;
    
    -- Delete user preferences
    DELETE FROM public.user_preferences WHERE user_id = target_user_id;
    GET DIAGNOSTICS user_preferences_count = ROW_COUNT;
    
    -- Delete user settings
    DELETE FROM public.user_settings WHERE user_id = target_user_id;
    GET DIAGNOSTICS user_settings_count = ROW_COUNT;
    
    -- Delete profile (this should cascade but being explicit)
    DELETE FROM public.profiles WHERE id = target_user_id;
    GET DIAGNOSTICS profiles_count = ROW_COUNT;
    
    -- Return structured result
    RETURN json_build_object(
        'success', true,
        'user_id', target_user_id,
        'deleted', json_build_object(
            'chat_messages', chat_messages_count,
            'chat_sessions', chat_sessions_count,
            'recipe_feedback', recipe_feedback_count,
            'recipe_history', recipe_history_count,
            'saved_recipes', saved_recipes_count,
            'recipes', recipes_count,
            'macro_logs', macro_logs_count,
            'activity_feed', activity_feed_count,
            'fridge_scans', fridge_scans_count,
            'fridge_items', fridge_items_count,
            'pantry_items', pantry_items_count,
            'user_preferences', user_preferences_count,
            'user_settings', user_settings_count,
            'profiles', profiles_count
        )
    );
END;
$$;

-- Internal function - no direct access
REVOKE ALL ON FUNCTION public._delete_user_data_internal(UUID) FROM authenticated;
REVOKE ALL ON FUNCTION public._delete_user_data_internal(UUID) FROM anon;
REVOKE ALL ON FUNCTION public._delete_user_data_internal(UUID) FROM public;

COMMENT ON FUNCTION public._delete_user_data_internal(UUID) IS 
    'Internal function for user data deletion. Not directly callable.';
