-- ============================================================================
-- BiteWise Database Schema - Tracking Tables
-- Migration: 00005_tracking_tables.sql
-- Description: Creates daily_macro_logs and activity_feed tables
-- ============================================================================

-- ============================================================================
-- 1. DAILY_MACRO_LOGS TABLE
-- Maps to DailyMacroLog struct in DataManager.swift
-- ============================================================================

CREATE TABLE public.daily_macro_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    calories_consumed INTEGER DEFAULT 0,
    protein_consumed DECIMAL(6,2) DEFAULT 0,
    carbs_consumed DECIMAL(6,2) DEFAULT 0,
    fats_consumed DECIMAL(6,2) DEFAULT 0,
    
    -- One log per user per day
    CONSTRAINT unique_user_date UNIQUE (user_id, log_date)
);

-- Enable RLS
ALTER TABLE public.daily_macro_logs ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_macro_logs_user ON public.daily_macro_logs(user_id);
CREATE INDEX idx_macro_logs_date ON public.daily_macro_logs(log_date DESC);
CREATE INDEX idx_macro_logs_user_date ON public.daily_macro_logs(user_id, log_date DESC);

-- ============================================================================
-- 2. ACTIVITY_FEED TABLE (deferred but included for completeness)
-- Maps to ActivityItem.swift
-- ============================================================================

CREATE TABLE public.activity_feed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    activity_type TEXT NOT NULL
        CHECK (activity_type IN (
            'cooked_recipe', 
            'added_pantry_item', 
            'added_fridge_item', 
            'rated_recipe', 
            'favorited_recipe', 
            'submitted_feedback'
        )),
    title TEXT NOT NULL,
    related_id UUID,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.activity_feed ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_activity_feed_user ON public.activity_feed(user_id);
CREATE INDEX idx_activity_feed_type ON public.activity_feed(activity_type);
CREATE INDEX idx_activity_feed_created ON public.activity_feed(created_at DESC);
CREATE INDEX idx_activity_feed_user_created ON public.activity_feed(user_id, created_at DESC);

-- ============================================================================
-- 3. HELPER FUNCTION: GET OR CREATE TODAY'S MACRO LOG
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_daily_macro_log(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    -- Try to get existing log for today
    SELECT id INTO v_log_id
    FROM public.daily_macro_logs
    WHERE user_id = p_user_id AND log_date = CURRENT_DATE;
    
    -- Create if not exists
    IF v_log_id IS NULL THEN
        INSERT INTO public.daily_macro_logs (user_id, log_date)
        VALUES (p_user_id, CURRENT_DATE)
        RETURNING id INTO v_log_id;
    END IF;
    
    RETURN v_log_id;
END;
$$;

-- ============================================================================
-- 4. HELPER FUNCTION: ADD MACROS TO TODAY'S LOG
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_macros_to_daily_log(
    p_user_id UUID,
    p_calories INTEGER,
    p_protein DECIMAL,
    p_carbs DECIMAL,
    p_fats DECIMAL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.daily_macro_logs (user_id, log_date, calories_consumed, protein_consumed, carbs_consumed, fats_consumed)
    VALUES (p_user_id, CURRENT_DATE, p_calories, p_protein, p_carbs, p_fats)
    ON CONFLICT (user_id, log_date)
    DO UPDATE SET
        calories_consumed = daily_macro_logs.calories_consumed + p_calories,
        protein_consumed = daily_macro_logs.protein_consumed + p_protein,
        carbs_consumed = daily_macro_logs.carbs_consumed + p_carbs,
        fats_consumed = daily_macro_logs.fats_consumed + p_fats;
END;
$$;

-- ============================================================================
-- 5. HELPER FUNCTION: LOG ACTIVITY
-- ============================================================================

CREATE OR REPLACE FUNCTION public.log_activity(
    p_user_id UUID,
    p_activity_type TEXT,
    p_title TEXT,
    p_related_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_activity_id UUID;
BEGIN
    INSERT INTO public.activity_feed (user_id, activity_type, title, related_id)
    VALUES (p_user_id, p_activity_type, p_title, p_related_id)
    RETURNING id INTO v_activity_id;
    
    -- Keep only the last 50 activities per user (matches iOS maxActivityLogSize)
    DELETE FROM public.activity_feed
    WHERE user_id = p_user_id
    AND id NOT IN (
        SELECT id FROM public.activity_feed
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 50
    );
    
    RETURN v_activity_id;
END;
$$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.daily_macro_logs IS 'Daily nutritional tracking - one row per user per day';
COMMENT ON TABLE public.activity_feed IS 'User activity log for recent actions display';

COMMENT ON COLUMN public.daily_macro_logs.log_date IS 'Date only (no time) for daily aggregation';
COMMENT ON COLUMN public.activity_feed.activity_type IS 'Matches ActivityType enum in ActivityItem.swift';
COMMENT ON COLUMN public.activity_feed.related_id IS 'Optional reference to recipe, ingredient, etc.';

COMMENT ON FUNCTION public.get_or_create_daily_macro_log IS 'Gets today macro log or creates if not exists';
COMMENT ON FUNCTION public.add_macros_to_daily_log IS 'Adds macro values to today log (upsert pattern)';
COMMENT ON FUNCTION public.log_activity IS 'Logs activity and maintains max 50 entries per user';
