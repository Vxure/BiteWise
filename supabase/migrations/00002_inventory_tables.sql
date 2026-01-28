-- ============================================================================
-- BiteWise Database Schema - Inventory Tables
-- Migration: 00002_inventory_tables.sql
-- Description: Creates ingredients catalog, fridge_scans, fridge_items, pantry_items
-- ============================================================================

-- ============================================================================
-- 1. INGREDIENTS TABLE (shared lookup/catalog)
-- ============================================================================

CREATE TABLE public.ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'other'
        CHECK (category IN ('protein', 'dairy', 'vegetable', 'fruit', 
                            'grain', 'condiment', 'beverage', 'other')),
    is_common BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- Ensure normalized names are unique for deduplication
    CONSTRAINT unique_normalized_name UNIQUE (normalized_name)
);

-- Enable RLS (public read, admin write)
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

-- Indexes for fast lookups
CREATE INDEX idx_ingredients_normalized ON public.ingredients(normalized_name);
CREATE INDEX idx_ingredients_category ON public.ingredients(category);
CREATE INDEX idx_ingredients_common ON public.ingredients(is_common) WHERE is_common = true;

-- ============================================================================
-- 2. FRIDGE_SCANS TABLE (tracks photo uploads)
-- ============================================================================

CREATE TABLE public.fridge_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    image_path TEXT,
    scanned_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    merge_mode TEXT DEFAULT 'Smart Merge'
        CHECK (merge_mode IN ('Replace All', 'Add to Existing', 'Smart Merge'))
);

-- Enable RLS
ALTER TABLE public.fridge_scans ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_fridge_scans_user ON public.fridge_scans(user_id);
CREATE INDEX idx_fridge_scans_date ON public.fridge_scans(scanned_at DESC);
CREATE INDEX idx_fridge_scans_user_date ON public.fridge_scans(user_id, scanned_at DESC);

-- ============================================================================
-- 3. FRIDGE_ITEMS TABLE (detected/added ingredients)
-- Maps to FridgeItem.swift
-- ============================================================================

CREATE TABLE public.fridge_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    scan_id UUID REFERENCES public.fridge_scans(id) ON DELETE SET NULL,
    ingredient_id UUID REFERENCES public.ingredients(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    quantity TEXT DEFAULT '',
    category TEXT DEFAULT 'other'
        CHECK (category IN ('protein', 'dairy', 'vegetable', 'fruit', 
                            'grain', 'condiment', 'beverage', 'other')),
    is_staple BOOLEAN DEFAULT false,
    date_added TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE public.fridge_items ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_fridge_items_user ON public.fridge_items(user_id);
CREATE INDEX idx_fridge_items_scan ON public.fridge_items(scan_id);
CREATE INDEX idx_fridge_items_date ON public.fridge_items(date_added DESC);
CREATE INDEX idx_fridge_items_user_date ON public.fridge_items(user_id, date_added DESC);
CREATE INDEX idx_fridge_items_category ON public.fridge_items(category);
CREATE INDEX idx_fridge_items_expires ON public.fridge_items(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================================================
-- 4. PANTRY_ITEMS TABLE (staple ingredients)
-- Maps to Ingredient.swift (pantry context)
-- ============================================================================

CREATE TABLE public.pantry_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    ingredient_id UUID REFERENCES public.ingredients(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    quantity TEXT DEFAULT '',
    unit TEXT DEFAULT '',
    is_staple BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.pantry_items ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_pantry_items_user ON public.pantry_items(user_id);
CREATE INDEX idx_pantry_items_name ON public.pantry_items(name);

-- Auto-update updated_at
CREATE TRIGGER update_pantry_items_updated_at
    BEFORE UPDATE ON public.pantry_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.ingredients IS 'Shared ingredient catalog for normalization and autocomplete';
COMMENT ON TABLE public.fridge_scans IS 'Records of fridge photo scans with merge mode used';
COMMENT ON TABLE public.fridge_items IS 'User fridge inventory - items detected from scans or added manually';
COMMENT ON TABLE public.pantry_items IS 'User pantry staples - items always assumed available';

COMMENT ON COLUMN public.ingredients.normalized_name IS 'Lowercase, trimmed name for deduplication and matching';
COMMENT ON COLUMN public.ingredients.is_common IS 'Flag for prioritizing in autocomplete suggestions';
COMMENT ON COLUMN public.fridge_items.scan_id IS 'References the scan that detected this item (NULL if manually added)';
COMMENT ON COLUMN public.fridge_items.ingredient_id IS 'Optional link to normalized ingredient catalog';
COMMENT ON COLUMN public.fridge_items.is_staple IS 'If true, item is not deducted when cooking recipes';
COMMENT ON COLUMN public.pantry_items.is_staple IS 'Pantry items default to staple=true (not deducted when cooking)';
