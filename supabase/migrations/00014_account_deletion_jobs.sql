-- Migration: Account Deletion Jobs Queue
-- Description: Creates a job queue table for robust, idempotent account deletion with retries

-- ============================================================================
-- 1. ACCOUNT DELETION JOBS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.account_deletion_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retries INTEGER NOT NULL DEFAULT 5,
    last_error TEXT,
    -- Track which steps have completed for idempotency
    db_deleted BOOLEAN NOT NULL DEFAULT false,
    storage_deleted BOOLEAN NOT NULL DEFAULT false,
    auth_deleted BOOLEAN NOT NULL DEFAULT false,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    next_retry_at TIMESTAMPTZ,
    -- Prevent duplicate jobs for the same user
    CONSTRAINT unique_pending_job_per_user UNIQUE (user_id, status) 
        DEFERRABLE INITIALLY DEFERRED
);

-- Create index for efficient job processing queries
CREATE INDEX IF NOT EXISTS idx_deletion_jobs_status_retry 
    ON public.account_deletion_jobs (status, next_retry_at) 
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX IF NOT EXISTS idx_deletion_jobs_user_id 
    ON public.account_deletion_jobs (user_id);

-- ============================================================================
-- 2. UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_deletion_job_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_deletion_job_updated_at ON public.account_deletion_jobs;
CREATE TRIGGER trigger_update_deletion_job_updated_at
    BEFORE UPDATE ON public.account_deletion_jobs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_deletion_job_updated_at();

-- ============================================================================
-- 3. REQUEST ACCOUNT DELETION RPC
-- ============================================================================

-- This function is called by the client to request account deletion
-- It creates a job record if one doesn't already exist for this user
CREATE OR REPLACE FUNCTION public.request_account_deletion()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id UUID;
    existing_job RECORD;
    new_job RECORD;
BEGIN
    -- Get the current authenticated user's ID
    current_user_id := auth.uid();
    
    -- Ensure user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Check for existing pending/processing job
    SELECT * INTO existing_job 
    FROM public.account_deletion_jobs 
    WHERE user_id = current_user_id 
      AND status IN ('pending', 'processing')
    LIMIT 1;
    
    IF existing_job IS NOT NULL THEN
        -- Return existing job info
        RETURN json_build_object(
            'success', true,
            'job_id', existing_job.id,
            'status', existing_job.status,
            'message', 'Deletion already in progress'
        );
    END IF;
    
    -- Check for recently completed job (within last hour) to prevent re-creation
    SELECT * INTO existing_job 
    FROM public.account_deletion_jobs 
    WHERE user_id = current_user_id 
      AND status = 'completed'
      AND completed_at > now() - interval '1 hour'
    LIMIT 1;
    
    IF existing_job IS NOT NULL THEN
        RETURN json_build_object(
            'success', true,
            'job_id', existing_job.id,
            'status', 'completed',
            'message', 'Account already deleted'
        );
    END IF;
    
    -- Create new deletion job
    INSERT INTO public.account_deletion_jobs (user_id, status, next_retry_at)
    VALUES (current_user_id, 'pending', now())
    RETURNING * INTO new_job;
    
    RETURN json_build_object(
        'success', true,
        'job_id', new_job.id,
        'status', new_job.status,
        'message', 'Deletion job created'
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.request_account_deletion() TO authenticated;

-- Explicitly revoke from anonymous and public roles
REVOKE ALL ON FUNCTION public.request_account_deletion() FROM anon;
REVOKE ALL ON FUNCTION public.request_account_deletion() FROM public;

-- ============================================================================
-- 4. GET DELETION JOB STATUS RPC
-- ============================================================================

-- Allows users to check the status of their deletion job
CREATE OR REPLACE FUNCTION public.get_deletion_job_status()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id UUID;
    job RECORD;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get the most recent job for this user
    SELECT * INTO job 
    FROM public.account_deletion_jobs 
    WHERE user_id = current_user_id 
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF job IS NULL THEN
        RETURN json_build_object(
            'success', true,
            'has_job', false,
            'message', 'No deletion job found'
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'has_job', true,
        'job_id', job.id,
        'status', job.status,
        'retry_count', job.retry_count,
        'db_deleted', job.db_deleted,
        'storage_deleted', job.storage_deleted,
        'auth_deleted', job.auth_deleted,
        'created_at', job.created_at,
        'completed_at', job.completed_at,
        'last_error', job.last_error
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_deletion_job_status() TO authenticated;
REVOKE ALL ON FUNCTION public.get_deletion_job_status() FROM anon;
REVOKE ALL ON FUNCTION public.get_deletion_job_status() FROM public;

-- ============================================================================
-- 5. RLS POLICIES FOR DELETION JOBS
-- ============================================================================

ALTER TABLE public.account_deletion_jobs ENABLE ROW LEVEL SECURITY;

-- Users can only view their own deletion jobs
CREATE POLICY "Users can view own deletion jobs"
    ON public.account_deletion_jobs FOR SELECT
    USING (auth.uid() = user_id);

-- Users cannot directly insert/update/delete - only through RPC
-- Service role can do everything (for the Edge Function)

-- ============================================================================
-- 6. COMMENTS
-- ============================================================================

COMMENT ON TABLE public.account_deletion_jobs IS 
    'Queue for account deletion jobs with retry support and idempotency tracking';

COMMENT ON FUNCTION public.request_account_deletion() IS 
    'Request account deletion - creates a job if not already pending';

COMMENT ON FUNCTION public.get_deletion_job_status() IS 
    'Get the status of the current user''s deletion job';
