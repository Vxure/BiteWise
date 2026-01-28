-- ============================================================================
-- BiteWise Database Schema - Clear Functions (RPCs)
-- Migration: 00007_clear_functions.sql
-- Description: Creates RPCs to clear data AND update last_*_clear_at timestamps
-- ============================================================================

-- ============================================================================
-- 1. CLEAR FRIDGE ITEMS
-- Deletes all fridge items for the user and updates last_fridge_clear_at
-- ============================================================================

CREATE OR REPLACE FUNCTION public.clear_fridge_items()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
    v_clear_time TIMESTAMPTZ;
BEGIN
    -- Get current time for consistency
    v_clear_time := now();
    
    -- Delete all fridge items for the authenticated user
    DELETE FROM public.fridge_items 
    WHERE user_id = auth.uid();
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Update the last_fridge_clear_at timestamp in user_settings
    UPDATE public.user_settings
    SET last_fridge_clear_at = v_clear_time,
        updated_at = v_clear_time
    WHERE user_id = auth.uid();
    
    -- Return summary
    RETURN jsonb_build_object(
        'success', true,
        'deleted_count', v_deleted_count,
        'cleared_at', v_clear_time
    );
END;
$$;

-- ============================================================================
-- 2. CLEAR PANTRY ITEMS
-- Deletes all pantry items for the user and updates last_pantry_clear_at
-- ============================================================================

CREATE OR REPLACE FUNCTION public.clear_pantry_items()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
    v_clear_time TIMESTAMPTZ;
BEGIN
    -- Get current time for consistency
    v_clear_time := now();
    
    -- Delete all pantry items for the authenticated user
    DELETE FROM public.pantry_items 
    WHERE user_id = auth.uid();
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Update the last_pantry_clear_at timestamp in user_settings
    UPDATE public.user_settings
    SET last_pantry_clear_at = v_clear_time,
        updated_at = v_clear_time
    WHERE user_id = auth.uid();
    
    -- Return summary
    RETURN jsonb_build_object(
        'success', true,
        'deleted_count', v_deleted_count,
        'cleared_at', v_clear_time
    );
END;
$$;

-- ============================================================================
-- 3. CLEAR CHAT HISTORY
-- Deletes all chat sessions (messages cascade) and updates last_chat_clear_at
-- ============================================================================

CREATE OR REPLACE FUNCTION public.clear_chat_history()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sessions_deleted INTEGER;
    v_messages_deleted INTEGER;
    v_clear_time TIMESTAMPTZ;
BEGIN
    -- Get current time for consistency
    v_clear_time := now();
    
    -- Count messages that will be deleted (before cascade)
    SELECT COUNT(*) INTO v_messages_deleted
    FROM public.chat_messages
    WHERE session_id IN (
        SELECT id FROM public.chat_sessions WHERE user_id = auth.uid()
    );
    
    -- Delete all chat sessions for the authenticated user
    -- (chat_messages are cascade-deleted via FK)
    DELETE FROM public.chat_sessions 
    WHERE user_id = auth.uid();
    
    GET DIAGNOSTICS v_sessions_deleted = ROW_COUNT;
    
    -- Update the last_chat_clear_at timestamp in user_settings
    UPDATE public.user_settings
    SET last_chat_clear_at = v_clear_time,
        updated_at = v_clear_time
    WHERE user_id = auth.uid();
    
    -- Return summary
    RETURN jsonb_build_object(
        'success', true,
        'sessions_deleted', v_sessions_deleted,
        'messages_deleted', v_messages_deleted,
        'cleared_at', v_clear_time
    );
END;
$$;

-- ============================================================================
-- 4. CLEAR ALL USER DATA (optional - for account reset)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.clear_all_user_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_fridge_result jsonb;
    v_pantry_result jsonb;
    v_chat_result jsonb;
    v_recipes_deleted INTEGER;
    v_history_deleted INTEGER;
    v_feedback_deleted INTEGER;
    v_macros_deleted INTEGER;
    v_activity_deleted INTEGER;
BEGIN
    -- Clear fridge, pantry, and chat using existing functions
    v_fridge_result := public.clear_fridge_items();
    v_pantry_result := public.clear_pantry_items();
    v_chat_result := public.clear_chat_history();
    
    -- Delete user's recipes
    DELETE FROM public.recipes WHERE user_id = auth.uid();
    GET DIAGNOSTICS v_recipes_deleted = ROW_COUNT;
    
    -- Delete recipe history (saved_recipes cascade with recipes)
    DELETE FROM public.recipe_history WHERE user_id = auth.uid();
    GET DIAGNOSTICS v_history_deleted = ROW_COUNT;
    
    -- Delete feedback
    DELETE FROM public.recipe_feedback WHERE user_id = auth.uid();
    GET DIAGNOSTICS v_feedback_deleted = ROW_COUNT;
    
    -- Delete macro logs
    DELETE FROM public.daily_macro_logs WHERE user_id = auth.uid();
    GET DIAGNOSTICS v_macros_deleted = ROW_COUNT;
    
    -- Delete activity feed
    DELETE FROM public.activity_feed WHERE user_id = auth.uid();
    GET DIAGNOSTICS v_activity_deleted = ROW_COUNT;
    
    -- Reset user preferences to defaults (don't delete, just reset)
    UPDATE public.user_preferences
    SET dietary_preferences = '{}',
        allergies = '{}',
        daily_calories = 2000,
        protein_percentage = 30.00,
        carbs_percentage = 40.00,
        fats_percentage = 30.00,
        has_macro_goals = false,
        updated_at = now()
    WHERE user_id = auth.uid();
    
    -- Return comprehensive summary
    RETURN jsonb_build_object(
        'success', true,
        'fridge', v_fridge_result,
        'pantry', v_pantry_result,
        'chat', v_chat_result,
        'recipes_deleted', v_recipes_deleted,
        'history_deleted', v_history_deleted,
        'feedback_deleted', v_feedback_deleted,
        'macros_deleted', v_macros_deleted,
        'activity_deleted', v_activity_deleted
    );
END;
$$;

-- ============================================================================
-- 5. GET USER CLEAR TIMESTAMPS
-- Convenience function to get all clear timestamps at once
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_clear_timestamps()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'last_fridge_clear_at', last_fridge_clear_at,
        'last_pantry_clear_at', last_pantry_clear_at,
        'last_chat_clear_at', last_chat_clear_at,
        'updated_at', updated_at
    ) INTO v_result
    FROM public.user_settings
    WHERE user_id = auth.uid();
    
    RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION public.clear_fridge_items IS 
    'Clears all fridge items and updates last_fridge_clear_at timestamp';

COMMENT ON FUNCTION public.clear_pantry_items IS 
    'Clears all pantry items and updates last_pantry_clear_at timestamp';

COMMENT ON FUNCTION public.clear_chat_history IS 
    'Clears all chat sessions/messages and updates last_chat_clear_at timestamp';

COMMENT ON FUNCTION public.clear_all_user_data IS 
    'Clears ALL user data except profile - use for account reset';

COMMENT ON FUNCTION public.get_clear_timestamps IS 
    'Returns all last_*_clear_at timestamps for the authenticated user';
