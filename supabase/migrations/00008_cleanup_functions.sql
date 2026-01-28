-- ============================================================================
-- BiteWise Database Schema - Scheduled Cleanup Functions
-- Migration: 00008_cleanup_functions.sql
-- Description: Creates functions for auto-deleting expired data based on user settings
-- ============================================================================

-- ============================================================================
-- 1. CLEANUP EXPIRED FRIDGE ITEMS
-- Deletes fridge items older than user's configured expiry days
-- Should be called daily via pg_cron or Supabase Edge Function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_fridge_items()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_deleted INTEGER := 0;
    v_user_record RECORD;
    v_deleted_for_user INTEGER;
BEGIN
    -- Loop through users with auto-expire enabled
    FOR v_user_record IN 
        SELECT user_id, fridge_auto_expire_days 
        FROM public.user_settings 
        WHERE fridge_auto_expire_enabled = true
    LOOP
        -- Delete expired items for this user
        DELETE FROM public.fridge_items
        WHERE user_id = v_user_record.user_id
          AND date_added < (now() - (v_user_record.fridge_auto_expire_days || ' days')::interval);
        
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

-- ============================================================================
-- 2. CLEANUP EXPIRED CHAT SESSIONS
-- Deletes chat sessions older than user's configured expiry days
-- Respects keep_recipe_chats_longer setting
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_chats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_general_deleted INTEGER := 0;
    v_recipe_deleted INTEGER := 0;
    v_user_record RECORD;
    v_deleted_count INTEGER;
BEGIN
    -- Loop through users with chat auto-expire enabled
    FOR v_user_record IN 
        SELECT 
            user_id, 
            general_chat_expire_days,
            recipe_chat_expire_days,
            keep_recipe_chats_longer
        FROM public.user_settings 
        WHERE chat_auto_expire_enabled = true
    LOOP
        -- Delete expired general chats (recipe_id IS NULL)
        DELETE FROM public.chat_sessions
        WHERE user_id = v_user_record.user_id
          AND recipe_id IS NULL
          AND updated_at < (now() - (v_user_record.general_chat_expire_days || ' days')::interval);
        
        GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
        v_general_deleted := v_general_deleted + v_deleted_count;
        
        -- Delete expired recipe chats
        -- Use recipe_chat_expire_days if keep_recipe_chats_longer is true
        -- Otherwise use general_chat_expire_days
        IF v_user_record.keep_recipe_chats_longer THEN
            DELETE FROM public.chat_sessions
            WHERE user_id = v_user_record.user_id
              AND recipe_id IS NOT NULL
              AND updated_at < (now() - (v_user_record.recipe_chat_expire_days || ' days')::interval);
        ELSE
            DELETE FROM public.chat_sessions
            WHERE user_id = v_user_record.user_id
              AND recipe_id IS NOT NULL
              AND updated_at < (now() - (v_user_record.general_chat_expire_days || ' days')::interval);
        END IF;
        
        GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
        v_recipe_deleted := v_recipe_deleted + v_deleted_count;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'general_sessions_deleted', v_general_deleted,
        'recipe_sessions_deleted', v_recipe_deleted,
        'total_deleted', v_general_deleted + v_recipe_deleted,
        'cleaned_at', now()
    );
END;
$$;

-- ============================================================================
-- 3. CLEANUP OLD ACTIVITY FEED ENTRIES
-- Keeps only the last 50 entries per user (matches iOS maxActivityLogSize)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_activity_feed()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_deleted INTEGER := 0;
    v_user_record RECORD;
    v_deleted_for_user INTEGER;
BEGIN
    -- For each user, delete activities beyond the 50 most recent
    FOR v_user_record IN 
        SELECT DISTINCT user_id FROM public.activity_feed
    LOOP
        DELETE FROM public.activity_feed
        WHERE user_id = v_user_record.user_id
        AND id NOT IN (
            SELECT id FROM public.activity_feed
            WHERE user_id = v_user_record.user_id
            ORDER BY created_at DESC
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

-- ============================================================================
-- 4. CLEANUP OLD FRIDGE SCANS (optional - keep last 30 scans per user)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_fridge_scans()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_deleted INTEGER := 0;
    v_user_record RECORD;
    v_deleted_for_user INTEGER;
BEGIN
    -- For each user, keep only the last 30 scans
    FOR v_user_record IN 
        SELECT DISTINCT user_id FROM public.fridge_scans
    LOOP
        DELETE FROM public.fridge_scans
        WHERE user_id = v_user_record.user_id
        AND id NOT IN (
            SELECT id FROM public.fridge_scans
            WHERE user_id = v_user_record.user_id
            ORDER BY scanned_at DESC
            LIMIT 30
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

-- ============================================================================
-- 5. MASTER CLEANUP FUNCTION
-- Runs all cleanup tasks - call this from pg_cron or scheduled Edge Function
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
BEGIN
    -- Run all cleanup functions
    v_fridge_result := public.cleanup_expired_fridge_items();
    v_chat_result := public.cleanup_expired_chats();
    v_activity_result := public.cleanup_activity_feed();
    v_scans_result := public.cleanup_old_fridge_scans();
    
    RETURN jsonb_build_object(
        'success', true,
        'fridge_items', v_fridge_result,
        'chat_sessions', v_chat_result,
        'activity_feed', v_activity_result,
        'fridge_scans', v_scans_result,
        'completed_at', now()
    );
END;
$$;

-- ============================================================================
-- 6. PG_CRON SETUP (run manually in Supabase SQL Editor if pg_cron enabled)
-- ============================================================================

-- Uncomment and run in Supabase SQL Editor if pg_cron is enabled:
-- 
-- -- Enable pg_cron extension (if not already)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;
-- 
-- -- Schedule daily cleanup at 3 AM UTC
-- SELECT cron.schedule(
--     'daily-cleanup',
--     '0 3 * * *',
--     $$SELECT public.run_daily_cleanup()$$
-- );
-- 
-- -- To view scheduled jobs:
-- SELECT * FROM cron.job;
-- 
-- -- To remove the job:
-- SELECT cron.unschedule('daily-cleanup');

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION public.cleanup_expired_fridge_items IS 
    'Deletes fridge items past their expiry based on user settings. Run daily.';

COMMENT ON FUNCTION public.cleanup_expired_chats IS 
    'Deletes chat sessions past their expiry based on user settings. Respects keep_recipe_chats_longer.';

COMMENT ON FUNCTION public.cleanup_activity_feed IS 
    'Keeps only last 50 activity entries per user (matches iOS limit).';

COMMENT ON FUNCTION public.cleanup_old_fridge_scans IS 
    'Keeps only last 30 fridge scan records per user.';

COMMENT ON FUNCTION public.run_daily_cleanup IS 
    'Master function that runs all cleanup tasks. Schedule via pg_cron or Edge Function.';
