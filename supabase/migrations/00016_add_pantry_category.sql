-- Add category column to pantry_items for sorting and grouping
ALTER TABLE public.pantry_items ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'other';

-- Index for category-based queries per user
CREATE INDEX IF NOT EXISTS idx_pantry_items_user_category ON public.pantry_items(user_id, category);
