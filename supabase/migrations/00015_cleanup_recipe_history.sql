-- ============================================================================
-- BiteWise Database Schema - Recipe History Cleanup
-- Migration: 00015_cleanup_recipe_history.sql
-- Description: Adds cleanup function for recipe_history table and wires it
--              into the existing run_daily_cleanup() master function.
--              Preserves saved_recipes (favorites) — only prunes the
--              cook-log in recipe_history.
-- ============================================================================

-- ============================================================================
-- 1. CLEANUP OLD RECIPE HISTORY
-- Keeps only the last 50 recipe_history entries per user.
-- iOS client caps at 20; 50 server-side gives comfortable headroom for
-- multi-device sync and historical queries.
--
-- NOTE: This deletes from recipe_history ONLY (the "cooked" log).
--       saved_recipes (favorites) is a separate table and is never touched.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_recipe_history()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_deleted INTEGER := 0;
    v_user_record RECORD;
    v_deleted_for_user INTEGER;
BEGIN
    -- For each user, keep only the 50 most recent recipe_history entries
    FOR v_user_record IN 
        SELECT DISTINCT user_id FROM public.recipe_history
    LOOP
        DELETE FROM public.recipe_history
        WHERE user_id = v_user_record.user_id
        AND id NOT IN (
            SELECT id FROM public.recipe_history
            WHERE user_id = v_user_record.user_id
            ORDER BY cooked_at DESC
            LIMIT 50
        );
        
        GET DIAGNOSTICS v_deleted_for_user = ROW_COUNT;
        v_total_deleted := v_total_deleted + v_deleted_for_user;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'total_deleted', v_total_deleted,
        'cleaned_at', now()
    );
END;
$$;

COMMENT ON FUNCTION public.cleanup_old_recipe_history IS 
    'Keeps only last 50 recipe history entries per user (matches iOS cap pattern). Does NOT affect saved_recipes.';

-- ============================================================================
-- 2. UPDATE MASTER CLEANUP FUNCTION
-- Add recipe_history cleanup to run_daily_cleanup() so it runs automatically
-- alongside the other cleanup tasks.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.run_daily_cleanup()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_fridge_result jsonb;
    v_chat_result jsonb;
    v_activity_result jsonb;
    v_scans_result jsonb;
    v_recipe_history_result jsonb;
BEGIN
    -- Run all cleanup functions
    v_fridge_result := public.cleanup_expired_fridge_items();
    v_chat_result := public.cleanup_expired_chats();
    v_activity_result := public.cleanup_activity_feed();
    v_scans_result := public.cleanup_old_fridge_scans();
    v_recipe_history_result := public.cleanup_old_recipe_history();
    
    RETURN jsonb_build_object(
        'success', true,
        'fridge_items', v_fridge_result,
        'chat_sessions', v_chat_result,
        'activity_feed', v_activity_result,
        'fridge_scans', v_scans_result,
        'recipe_history', v_recipe_history_result,
        'completed_at', now()
    );
END;
$$;

COMMENT ON FUNCTION public.run_daily_cleanup IS 
    'Master function that runs all cleanup tasks including recipe history. Schedule via pg_cron or Edge Function.';
