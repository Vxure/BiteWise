-- ============================================================================
-- BiteWise Database Schema - Foundation Tables
-- Migration: 00001_foundation_tables.sql
-- Description: Creates profiles, user_preferences, and user_settings tables
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create index for email lookups
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- Trigger function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 2. USER_PREFERENCES TABLE (dietary preferences, allergies, macro goals)
-- ============================================================================

CREATE TABLE public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    dietary_preferences TEXT[] DEFAULT '{}',
    allergies TEXT[] DEFAULT '{}',
    daily_calories INTEGER DEFAULT 2000,
    protein_percentage DECIMAL(5,2) DEFAULT 30.00,
    carbs_percentage DECIMAL(5,2) DEFAULT 40.00,
    fats_percentage DECIMAL(5,2) DEFAULT 30.00,
    has_macro_goals BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- Ensure macro percentages sum to 100
    CONSTRAINT valid_percentages CHECK (
        protein_percentage + carbs_percentage + fats_percentage = 100
    ),
    -- One preferences record per user
    CONSTRAINT unique_user_preferences UNIQUE (user_id)
);

-- Enable RLS
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Index for user lookups
CREATE INDEX idx_user_preferences_user ON public.user_preferences(user_id);

-- ============================================================================
-- 3. USER_SETTINGS TABLE (app settings, retention policies, clear timestamps)
-- ============================================================================

CREATE TABLE public.user_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Fridge auto-expire settings (matches AppSettings.swift)
    fridge_auto_expire_enabled BOOLEAN DEFAULT false,
    fridge_auto_expire_days INTEGER DEFAULT 7,
    
    -- Chat auto-expire settings (matches AppSettings.swift)
    chat_auto_expire_enabled BOOLEAN DEFAULT true,
    general_chat_expire_days INTEGER DEFAULT 15,
    recipe_chat_expire_days INTEGER DEFAULT 15,
    keep_recipe_chats_longer BOOLEAN DEFAULT false,
    
    -- Scan behavior (matches ScanMergeMode enum in FridgeItem.swift)
    default_scan_method TEXT DEFAULT 'Ask Every Time'
        CHECK (default_scan_method IN ('Ask Every Time', 'Replace All', 'Add to Existing', 'Smart Merge')),
    
    -- Clear timestamps (updated when user clears data)
    last_fridge_clear_at TIMESTAMPTZ,
    last_pantry_clear_at TIMESTAMPTZ,
    last_chat_clear_at TIMESTAMPTZ,
    
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. AUTO-CREATE PREFERENCES AND SETTINGS ON PROFILE CREATION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Create default user preferences
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    -- Create default user settings
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_profile_created
    AFTER INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_profile();

-- ============================================================================
-- 5. AUTO-UPDATE updated_at TIMESTAMPS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to profiles
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Apply to user_preferences
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Apply to user_settings
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users';
COMMENT ON TABLE public.user_preferences IS 'User dietary preferences, allergies, and macro goals';
COMMENT ON TABLE public.user_settings IS 'User app settings including retention policies';

COMMENT ON COLUMN public.user_settings.default_scan_method IS 'Matches ScanMergeMode enum: Ask Every Time, Replace All, Add to Existing, Smart Merge';
COMMENT ON COLUMN public.user_settings.last_fridge_clear_at IS 'Timestamp when user last cleared all fridge items';
COMMENT ON COLUMN public.user_settings.last_pantry_clear_at IS 'Timestamp when user last cleared all pantry items';
COMMENT ON COLUMN public.user_settings.last_chat_clear_at IS 'Timestamp when user last cleared all chat history';
