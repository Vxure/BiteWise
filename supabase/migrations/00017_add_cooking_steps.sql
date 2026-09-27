-- ============================================================================
-- BiteWise Database Schema - Add Cooking Steps
-- Migration: 00017_add_cooking_steps.sql
-- Description: Adds structured cooking_steps JSONB column to recipes table
--              for per-step titles, durations, ingredients, and chef tips
-- ============================================================================

ALTER TABLE public.recipes
ADD COLUMN cooking_steps JSONB DEFAULT NULL;

COMMENT ON COLUMN public.recipes.cooking_steps IS
    'Structured cooking steps array: [{"title":"...","instruction":"...","durationMinutes":5,"ingredients":["..."],"chefTip":"..."}]';
