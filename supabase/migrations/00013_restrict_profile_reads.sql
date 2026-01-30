-- ============================================================================
-- BiteWise Database Schema - Restrict Profile Reads
-- Migration: 00013_restrict_profile_reads.sql
-- Description: Remove the global profiles read policy to prevent PII exposure
-- ============================================================================

-- Remove global profile read policy (if it exists)
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;

-- Ensure own-profile read policy exists (idempotent safety)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'profiles'
          AND policyname = 'Users can view own profile'
    ) THEN
        CREATE POLICY "Users can view own profile"
            ON public.profiles FOR SELECT
            USING (auth.uid() = id);
    END IF;
END;
$$;
