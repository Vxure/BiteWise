-- ============================================================================
-- BiteWise Database Schema - Storage Buckets and Policies
-- Migration: 00009_storage_buckets.sql
-- Description: Creates storage buckets for fridge photos, recipe images, avatars
-- ============================================================================

-- ============================================================================
-- 1. CREATE STORAGE BUCKETS
-- ============================================================================

-- Fridge photos bucket (private - user's fridge scan images)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'fridge-photos',
    'fridge-photos',
    false,
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- Recipe images bucket (public - for sharing recipes)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'recipe-images',
    'recipe-images',
    true,
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- User avatars bucket (public - for profile pictures)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    2097152,  -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. FRIDGE PHOTOS STORAGE POLICIES (private bucket)
-- Path structure: fridge-photos/{user_id}/{scan_id}.jpg
-- ============================================================================

-- Allow users to upload their own fridge photos
CREATE POLICY "Users can upload own fridge photos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'fridge-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to view their own fridge photos
CREATE POLICY "Users can view own fridge photos"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'fridge-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to update their own fridge photos
CREATE POLICY "Users can update own fridge photos"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'fridge-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own fridge photos
CREATE POLICY "Users can delete own fridge photos"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'fridge-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- 3. RECIPE IMAGES STORAGE POLICIES (public bucket)
-- Path structure: recipe-images/{user_id}/{recipe_id}.jpg
-- ============================================================================

-- Anyone can view recipe images (public bucket)
CREATE POLICY "Anyone can view recipe images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'recipe-images');

-- Allow users to upload their own recipe images
CREATE POLICY "Users can upload own recipe images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'recipe-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to update their own recipe images
CREATE POLICY "Users can update own recipe images"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'recipe-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own recipe images
CREATE POLICY "Users can delete own recipe images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'recipe-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- 4. AVATARS STORAGE POLICIES (public bucket)
-- Path structure: avatars/{user_id}/avatar.jpg
-- ============================================================================

-- Anyone can view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- Allow users to upload their own avatar
CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to update their own avatar
CREATE POLICY "Users can update own avatar"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete own avatar"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- 5. HELPER FUNCTIONS FOR STORAGE PATHS
-- ============================================================================

-- Generate storage path for fridge photo
CREATE OR REPLACE FUNCTION public.get_fridge_photo_path(p_scan_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN auth.uid()::text || '/' || p_scan_id::text || '.jpg';
END;
$$;

-- Generate storage path for recipe image
CREATE OR REPLACE FUNCTION public.get_recipe_image_path(p_recipe_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN auth.uid()::text || '/' || p_recipe_id::text || '.jpg';
END;
$$;

-- Generate storage path for avatar
CREATE OR REPLACE FUNCTION public.get_avatar_path()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN auth.uid()::text || '/avatar.jpg';
END;
$$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION public.get_fridge_photo_path IS 
    'Returns the storage path for a fridge scan photo: {user_id}/{scan_id}.jpg';

COMMENT ON FUNCTION public.get_recipe_image_path IS 
    'Returns the storage path for a recipe image: {user_id}/{recipe_id}.jpg';

COMMENT ON FUNCTION public.get_avatar_path IS 
    'Returns the storage path for user avatar: {user_id}/avatar.jpg';
